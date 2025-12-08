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

private enum WebRTCStatsConstants {
    static let remoteInboundRtpType = "remote-inbound-rtp"
    static let inboundRtpType = "inbound-rtp"
    static let candidatePairType = "candidate-pair"
    static let codecType = "codec"
    static let trackType = "track"

    static let framesPerSecondKey = "framesPerSecond"
    static let framesDroppedKey = "framesDropped"
    static let bytesReceivedKey = "bytesReceived"
    static let packetsReceivedKey = "packetsReceived"
    static let packetsLostKey = "packetsLost"
    static let jitterKey = "jitter"
    static let frameWidthKey = "frameWidth"
    static let frameHeightKey = "frameHeight"
    static let codecIdKey = "codecId"
    static let mimeTypeKey = "mimeType"
    static let jitterBufferDelayKey = "jitterBufferDelay"
}

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didReceiveRemoteVideoTrack track: RTCVideoTrack)
}

final class WebRTCClient: NSObject {
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        return RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                        decoderFactory: RTCDefaultVideoDecoderFactory())
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection

    private let streamId = "KvsLocalMediaStream"
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
    private var constructedIceServers: [RTCIceServer]?
    
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
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, 
                                       with: .defaultToSpeaker)
            try audioSession.setMode(AVAudioSession.Mode.default.rawValue)
            try audioSession.overrideOutputAudioPort(.speaker)
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
        if pendingIceCandidatesMap.index(forKey: clientId) != nil {
            var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!;
            while !pendingIceCandidateListByClientId.isEmpty {
                let iceCandidate: RTCIceCandidate = pendingIceCandidateListByClientId.popFirst()!
                let peerConnectionCurrent : RTCPeerConnection = peerConnectionFoundMap[clientId]!
                peerConnectionCurrent.add(iceCandidate)
            }
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
        if peerConnectionFoundMap.index(forKey: clientId) == nil {
            if pendingIceCandidatesMap.index(forKey: clientId) != nil {
                var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
            else {
                var pendingIceCandidateListByClientId = Set<RTCIceCandidate>()
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
        }
        else {
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
        remoteVideoRenderers.append(renderer)
        
        if let remoteVideoTrack = remoteVideoTrack {
            remoteVideoTrack.add(renderer)
        }
    }
    
    private func handleRemoteVideoTrack(_ track: RTCVideoTrack) {
        self.remoteVideoTrack = track
        
        DispatchQueue.main.async {
            for renderer in self.remoteVideoRenderers {
                track.add(renderer)
            }
        }
        
        delegate?.webRTCClient(self, didReceiveRemoteVideoTrack: track)
    }
    
    func getFPS(completion: @escaping (Double) -> Void) {
        self.peerConnection.statistics { statsReport in
            for (_, stats) in statsReport.statistics {
                let type = stats.type
                if type == WebRTCStatsConstants.remoteInboundRtpType {
                    if let frameRate = stats.values[WebRTCStatsConstants.framesPerSecondKey] as? Double {
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
                if type == WebRTCStatsConstants.inboundRtpType {
                    if let frameRate = stats.values[WebRTCStatsConstants.framesPerSecondKey] as? Double {
                        fpsCompletion(frameRate)
                    }
                } else if type == WebRTCStatsConstants.candidatePairType {
                    if let frameHeight = stats.values[WebRTCStatsConstants.frameHeightKey] as? Double, let frameWidth = stats.values[WebRTCStatsConstants.frameWidthKey] as? Double {
                        frameSizeCompletion(frameHeight, frameWidth)
                    }
                }
            }
        }
    }
    
    func getDetailedStats(completion: @escaping (DetailedStats) -> Void) {
        self.peerConnection.statistics { statsReport in
            var stats = DetailedStats()
            var codecId: String? = nil

            for (_, stat) in statsReport.statistics where stat.type == WebRTCStatsConstants.inboundRtpType {
                if let frameRate = self.doubleValue(from: stat.values[WebRTCStatsConstants.framesPerSecondKey]) {
                    stats.currentFps = frameRate
                }
                stats.totalFramesDropped = self.int64Value(from: stat.values[WebRTCStatsConstants.framesDroppedKey]) ?? stats.totalFramesDropped
                stats.totalBytesReceived = self.int64Value(from: stat.values[WebRTCStatsConstants.bytesReceivedKey]) ?? stats.totalBytesReceived
                stats.totalPacketsReceived = self.int64Value(from: stat.values[WebRTCStatsConstants.packetsReceivedKey]) ?? stats.totalPacketsReceived
                stats.totalPacketsLost = self.int64Value(from: stat.values[WebRTCStatsConstants.packetsLostKey]) ?? stats.totalPacketsLost
                if let jitter = self.doubleValue(from: stat.values[WebRTCStatsConstants.jitterKey]) {
                    stats.jitterMs = jitter * 1000.0
                }
                stats.currentFrameWidth = self.intValue(from: stat.values[WebRTCStatsConstants.frameWidthKey]) ?? stats.currentFrameWidth
                stats.currentFrameHeight = self.intValue(from: stat.values[WebRTCStatsConstants.frameHeightKey]) ?? stats.currentFrameHeight
                codecId = stat.values[WebRTCStatsConstants.codecIdKey] as? String ?? codecId
            }

            stats.videoCodec = self.resolveVideoCodec(from: statsReport.statistics, preferredCodecId: codecId)

            if stats.jitterMs == 0 {
                stats.jitterMs = self.resolveTrackJitter(from: statsReport.statistics) ?? 0
            }
            
            stats.receivedFps = stats.currentFps
            
            completion(stats)
        }
    }

    private func createLocalVideoStream() {
        localVideoTrack = createVideoTrack()

        if let localVideoTrack = localVideoTrack {
            peerConnection.add(localVideoTrack, streamIds: [streamId])
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

    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
    }
    
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

private extension WebRTCClient {
    func resolveVideoCodec(from statistics: [String: RTCStatistics], preferredCodecId: String?) -> String {
        if let preferredCodecId = preferredCodecId {
            for (_, stat) in statistics where stat.type == WebRTCStatsConstants.codecType {
                if let id = stat.id as? String, id == preferredCodecId,
                   let mimeType = stat.values[WebRTCStatsConstants.mimeTypeKey] as? String {
                    return mimeType
                }
            }
        }

        for (_, stat) in statistics where stat.type == WebRTCStatsConstants.codecType {
            if let mimeType = stat.values[WebRTCStatsConstants.mimeTypeKey] as? String {
                return mimeType
            }
        }
        return "N/A"
    }

    func resolveTrackJitter(from statistics: [String: RTCStatistics]) -> Double? {
        for (_, stat) in statistics where stat.type == WebRTCStatsConstants.trackType {
            if let jitterBufferDelay = doubleValue(from: stat.values[WebRTCStatsConstants.jitterBufferDelayKey]) {
                return jitterBufferDelay
            }
        }
        return nil
    }

    func int64Value(from value: Any?) -> Int64? {
        switch value {
        case let int64Value as Int64:
            return int64Value
        case let intValue as Int:
            return Int64(intValue)
        case let doubleValue as Double:
            return Int64(doubleValue)
        case let number as NSNumber:
            return number.int64Value
        case let stringValue as String:
            return Int64(stringValue)
        default:
            return nil
        }
    }

    func intValue(from value: Any?) -> Int? {
        switch value {
        case let intValue as Int:
            return intValue
        case let int64Value as Int64:
            return Int(int64Value)
        case let doubleValue as Double:
            return Int(doubleValue)
        case let number as NSNumber:
            return number.intValue
        case let stringValue as String:
            return Int(stringValue)
        default:
            return nil
        }
    }

    func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let doubleValue as Double:
            return doubleValue
        case let intValue as Int:
            return Double(intValue)
        case let int64Value as Int64:
            return Double(int64Value)
        case let number as NSNumber:
            return number.doubleValue
        case let stringValue as String:
            return Double(stringValue)
        default:
            return nil
        }
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    }

    func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
