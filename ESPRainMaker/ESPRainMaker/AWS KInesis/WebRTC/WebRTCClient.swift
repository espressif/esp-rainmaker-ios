// Copyright 2025 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  WebRTCClient.swift
//  ESPRainMaker
//

import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didReceiveRemoteVideoTrack track: RTCVideoTrack)
}

final class WebRTCClient: NSObject {
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        //support all codec formats for encode and decode
        return RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                        decoderFactory: RTCDefaultVideoDecoderFactory())
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection

    // Accept video and audio from remote peer
    private let streamId = "KvsLocalMediaStream"
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
    private var constructedIceServers: [RTCIceServer]?
    
    // Store video renderers to add tracks when they become available
    private var remoteVideoRenderers: [RTCVideoRenderer] = []

    private var peerConnectionFoundMap = [String: RTCPeerConnection]()
    private var pendingIceCandidatesMap = [String: Set<RTCIceCandidate>]()

    required init(iceServers: [RTCIceServer], isAudioOn: Bool) {
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        config.keyType = .ECDSA
        config.rtcpMuxPolicy = .require
        config.tcpCandidatePolicy = .enabled

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)

        super.init()
        configureAudioSession()

        if (isAudioOn) {
        createLocalAudioStream()
        }
        createLocalVideoStream()
        peerConnection.delegate = self
    }

    func configureAudioSession() {
        let audioSession = RTCAudioSession.sharedInstance()
        audioSession.isAudioEnabled = false
        do {
            try? audioSession.lockForConfiguration()
            // Convert enum values to raw string values
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, 
                                       with: .defaultToSpeaker)
            try audioSession.setMode(AVAudioSession.Mode.default.rawValue)
            try audioSession.overrideOutputAudioPort(.speaker)
            // Updated renamed method
            try? AVAudioSession.sharedInstance().setActive(true, 
                                                         options: .notifyOthersOnDeactivation)
            audioSession.unlockForConfiguration()
        } catch {
            print("audioSession properties weren't set because of an error.")
            print(error.localizedDescription)
            audioSession.unlockForConfiguration()
        }
    }

    func shutdown() {
        peerConnection.close()

        if let stream = peerConnection.localStreams.first {
            localAudioTrack = nil
            localVideoTrack = nil
            remoteVideoTrack = nil
            peerConnection.remove(stream)
        }
        peerConnectionFoundMap.removeAll();
        pendingIceCandidatesMap.removeAll();
    }

    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.offer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.answer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func updatePeerConnectionAndHandleIceCandidates(clientId: String) {
        peerConnectionFoundMap[clientId] = peerConnection;
        handlePendingIceCandidates(clientId: clientId);
    }

    func handlePendingIceCandidates(clientId: String) {
        // Add any pending ICE candidates from the queue for the client ID
        if pendingIceCandidatesMap.index(forKey: clientId) != nil {
            var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!;
            while !pendingIceCandidateListByClientId.isEmpty {
                let iceCandidate: RTCIceCandidate = pendingIceCandidateListByClientId.popFirst()!
                let peerConnectionCurrent : RTCPeerConnection = peerConnectionFoundMap[clientId]!
                peerConnectionCurrent.add(iceCandidate)
            }
            // After sending pending ICE candidates, the client ID's peer connection need not be tracked
            pendingIceCandidatesMap.removeValue(forKey: clientId)
        }
    }

    func set(remoteSdp: RTCSessionDescription, clientId: String, completion: @escaping (Error?) -> Void) {
        peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
        if remoteSdp.type == RTCSdpType.answer {
            updatePeerConnectionAndHandleIceCandidates(clientId: clientId)
        }
    }

    func checkAndAddIceCandidate(remoteCandidate: RTCIceCandidate, clientId: String) {
        // if answer/offer is not received, it means peer connection is not found. Hold the received ICE candidates in the map.
        if peerConnectionFoundMap.index(forKey: clientId) == nil {

            // If the entry for the client ID already exists (in case of subsequent ICE candidates), update the queue
            if pendingIceCandidatesMap.index(forKey: clientId) != nil {
                var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
            // If the first ICE candidate before peer connection is received, add entry to map and ICE candidate to a queue
            else {
                var pendingIceCandidateListByClientId = Set<RTCIceCandidate>()
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
        }
        // This is the case where peer connection is established and ICE candidates are received for the established connection
        else {
            // Remote sent us ICE candidates, add to local peer connection
            let peerConnectionCurrent : RTCPeerConnection = peerConnectionFoundMap[clientId]!
            peerConnectionCurrent.add(remoteCandidate);
        }
    }

    func set(remoteCandidate: RTCIceCandidate, clientId: String) {
        checkAndAddIceCandidate(remoteCandidate: remoteCandidate, clientId: clientId)
    }

    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),

            let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).last,

            let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate else {
                return
            }

        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.magnitude))

        localVideoTrack?.add(renderer)
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        // Store the renderer for when remote track becomes available
        remoteVideoRenderers.append(renderer)
        
        // If we already have a remote video track, add it to the renderer
        if let remoteVideoTrack = remoteVideoTrack {
            remoteVideoTrack.add(renderer)
        } else {
        }
    }
    
    private func handleRemoteVideoTrack(_ track: RTCVideoTrack) {
        self.remoteVideoTrack = track
        
        // Add the track to all stored renderers
        DispatchQueue.main.async {
            for renderer in self.remoteVideoRenderers {
                track.add(renderer)
            }
        }
        
        // Notify delegate
        delegate?.webRTCClient(self, didReceiveRemoteVideoTrack: track)
    }
    
    func getFPS(completion: @escaping (Double) -> Void) {
        self.peerConnection.statistics { statsReport in
            for (_, stats) in statsReport.statistics {
                let type = stats.type
                if type == "remote-inbound-rtp" {
                    if let frameRate = stats.values["framesPerSecond"] as? Double {
                        completion(frameRate)
                        break
                    }
                }
            }
        }
    }
    
    func getStats(frameSizeCompletion: @escaping (Double, Double) -> Void, fpsCompletion: @escaping (Double) -> Void) {
        self.peerConnection.statistics { statsReport in
            for (_, stats) in statsReport.statistics {
                let type = stats.type
                if type == "inbound-rtp" {
                    if let frameRate = stats.values["framesPerSecond"] as? Double {
                        fpsCompletion(frameRate)
                    }
                } else if type == "candidate-pair" {
                    if let frameHeight = stats.values["frameHeight"] as? Double, let frameWidth = stats.values["frameWidth"] as? Double {
                        frameSizeCompletion(frameHeight, frameWidth)
                    }
                }
            }
        }
    }

    private func createLocalVideoStream() {
        localVideoTrack = createVideoTrack()

        if let localVideoTrack = localVideoTrack {
            peerConnection.add(localVideoTrack, streamIds: [streamId])
            // Don't try to get remote track here - it will come via didAdd track delegate
        }
    }

    private func createLocalAudioStream() {
        localAudioTrack = createAudioTrack()
        if let localAudioTrack  = localAudioTrack {
            peerConnection.add(localAudioTrack, streamIds: [streamId])
            let audioTracks = peerConnection.transceivers.compactMap { $0.sender.track as? RTCAudioTrack }
            audioTracks.forEach { $0.isEnabled = true }
        }
    }

    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClient.factory.videoSource()
        videoSource.adaptOutputFormat(toWidth: 1280, height: 720, fps: 30)
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        return WebRTCClient.factory.videoTrack(with: videoSource, trackId: "KvsVideoTrack")
    }

    private func createAudioTrack() -> RTCAudioTrack {
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: mediaConstraints)
        return WebRTCClient.factory.audioTrack(with: audioSource, trackId: "KvsAudioTrack")
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    }

    // DEPRECATED: This method is deprecated but keeping for compatibility
    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
    }
    
    // MODERN: Use this method for receiving remote tracks
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        
        guard let track = rtpReceiver.track else {
            return
        }
        
        if let videoTrack = track as? RTCVideoTrack {
            handleRemoteVideoTrack(videoTrack)
        } else if let audioTrack = track as? RTCAudioTrack {
            audioTrack.isEnabled = true
        }
    }

    func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.webRTCClient(self, didGenerate: candidate)
    }

    func peerConnection(_: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
    }

    func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        remoteDataChannel = dataChannel
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    }

    func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
