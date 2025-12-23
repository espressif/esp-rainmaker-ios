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
//  DeviceTraitListViewController+CameraActionDelegate.swift
//  ESPRainMaker
//

import AWSKinesisVideo
import AWSKinesisVideoSignaling
import AWSCore
import WebRTC

extension DeviceTraitListViewController {
    
    /// Launch kinesis video with new ESPVideoViewController (single controller)
    func launchESPVideoViewer(channel: String?) {
        guard let channelName = channel, !channelName.isEmpty else {
            DispatchQueue.main.async {
                self.showErrorAlert(title: "Error",
                                  message: "Channel name is required for video streaming",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        // Get the node ID from current context
        guard let nodeId = self.device.node?.node_id else {
            DispatchQueue.main.async {
                self.showErrorAlert(title: "Error",
                                  message: "Node ID is required for video streaming",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        // Show loader while getting credentials and setting up video
        DispatchQueue.main.async {
            Utility.showLoader(message: "Setting up video stream...", view: self.view)
        }
        
        // Get AWS credentials and setup WebRTC
        ESPAssumeRoleCredentialManager.shared.getAssumeRoleCredentials(nodeId: nodeId) { [weak self] credentials, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.showErrorAlert(title: "Error",
                                      message: "Failed to get AWS credentials: \(error.localizedDescription)",
                                      buttonTitle: "OK",
                                      callback: {})
                }
                return
            }
            
            guard let _ = credentials else {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.showErrorAlert(title: "Error",
                                      message: "Failed to get AWS credentials",
                                      buttonTitle: "OK",
                                      callback: {})
                }
                return
            }
            
            // Setup WebRTC and Signaling directly
            self.setupWebRTCAndLaunchViewer(channelName: channelName)
        }
    }
    
    private func setupWebRTCAndLaunchViewer(channelName: String) {
        var awsRegionValue = "ap-south-1"
        if let token = ESPTokenWorker.shared.idToken, let region = token.region {
            awsRegionValue = region
        }
        let awsRegionType = awsRegionValue.aws_regionTypeValue()
        // Generate a random UUID for local sender client ID each time stream starts
        let localSenderClientID = UUID().uuidString
        let isMaster = false
        let sendAudioEnabled = false
        
        // Configure Kinesis Video Client
        let configuration = AWSServiceConfiguration(region: awsRegionType,
                                                    credentialsProvider: ESPAssumeRoleCredentialsProvider.shared)
        guard let config = configuration else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error",
                                  message: "Failed to configure AWS service",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        AWSKinesisVideo.register(with: config, forKey: ESPAWSConstants.awsKinesisVideoKey)
        
        // Get or create channel ARN
        var channelARN = retrieveChannelARN(channelName: channelName)
        if channelARN == nil {
            channelARN = createChannel(channelName: channelName)
            if channelARN == nil {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                    self.showErrorAlert(title: "Error",
                                      message: "Unable to create channel",
                                      buttonTitle: "OK",
                                      callback: {})
                }
                return
            }
        }
        
        // Get signaling endpoints for viewer role
        guard let channelARN = channelARN else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error",
                                  message: "Channel ARN is required",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        let endpoints = getSignallingEndpoints(channelARN: channelARN,
                                             region: awsRegionValue,
                                             isMaster: false,
                                             useMediaServer: sendAudioEnabled)
        
        guard let wssEndpoint = endpoints["WSS"] else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error",
                                  message: "Failed to get signaling endpoints",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        guard let wssURL = createSignedWSSUrl(channelARN: channelARN,
                                       region: awsRegionValue,
                                       wssEndpoint: wssEndpoint,
                                       isMaster: false,
                                       clientId: localSenderClientID) else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error",
                                  message: "Failed to create signed WSS URL",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        // Get ICE server configuration
        guard let httpsEndpointString = endpoints["HTTPS"] as? String,
              let httpsURL = URL(string: httpsEndpointString) else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error",
                                  message: "Failed to get HTTPS endpoint",
                                  buttonTitle: "OK",
                                  callback: {})
            }
            return
        }
        
        let httpsEndpoint = AWSEndpoint(region: awsRegionType,
                                      service: .KinesisVideo,
                                      url: httpsURL)
        
        let RTCIceServersList = getIceCandidates(channelARN: channelARN,
                                                endpoint: httpsEndpoint,
                                                regionType: awsRegionType,
                                                clientId: localSenderClientID)
        
        // Initialize WebRTC client
        let webRTCClient = WebRTCClient(iceServers: RTCIceServersList, isAudioOn: sendAudioEnabled)
        
        // Initialize signaling client
        let signalingClient = SignalingClient(serverUrl: wssURL)
        
        // Create and present the new ESPVideoViewController
        let espVideoViewer = ESPVideoViewController(webRTCClient: webRTCClient,
                                                  signalingClient: signalingClient,
                                                  localSenderClientID: localSenderClientID,
                                                  isMaster: isMaster,
                                                  channelName: channelName)
        
        espVideoViewer.delegate = self
        
        // Set up delegates
        webRTCClient.delegate = espVideoViewer
        signalingClient.delegate = espVideoViewer
        
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.present(espVideoViewer, animated: true) {
                // Connect to signaling after presentation
                signalingClient.connect()
            }
        }
    }
    
    // MARK: - AWS Helper Methods
    
    private func retrieveChannelARN(channelName: String) -> String? {
        var channelARN: String?
        let describeInput = AWSKinesisVideoDescribeSignalingChannelInput()
        describeInput?.channelName = channelName
        
        let kvsClient = AWSKinesisVideo(forKey: ESPAWSConstants.awsKinesisVideoKey)
        kvsClient.describeSignalingChannel(describeInput!).continueWith(block: { (task) -> Void in
            if task.error == nil {
                channelARN = task.result?.channelInfo?.channelARN
            }
        }).waitUntilFinished()
        return channelARN
    }

    private func createChannel(channelName: String) -> String? {
        var channelARN: String?
        let kvsClient = AWSKinesisVideo(forKey: ESPAWSConstants.awsKinesisVideoKey)
        let createSignalingChannelInput = AWSKinesisVideoCreateSignalingChannelInput.init()
        createSignalingChannelInput?.channelName = channelName
        
        kvsClient.createSignalingChannel(createSignalingChannelInput!).continueWith(block: { (task) -> Void in
            if task.error == nil {
                channelARN = task.result?.channelARN
            }
        }).waitUntilFinished()
        return channelARN
    }
    
    private func getSignallingEndpoints(channelARN: String, region: String, isMaster: Bool, useMediaServer: Bool) -> Dictionary<String, String?> {
        var endpoints = Dictionary<String, String?>()
        
        let singleMasterChannelEndpointConfiguration = AWSKinesisVideoSingleMasterChannelEndpointConfiguration()
        singleMasterChannelEndpointConfiguration?.protocols = ["WSS", "HTTPS"]
        singleMasterChannelEndpointConfiguration?.role = isMaster ? .master : .viewer
        
        if useMediaServer {
            singleMasterChannelEndpointConfiguration?.protocols?.append("WEBRTC")
        }
        
        let kvsClient = AWSKinesisVideo(forKey: ESPAWSConstants.awsKinesisVideoKey)
        let signalingEndpointInput = AWSKinesisVideoGetSignalingChannelEndpointInput()
        signalingEndpointInput?.channelARN = channelARN
        signalingEndpointInput?.singleMasterChannelEndpointConfiguration = singleMasterChannelEndpointConfiguration
        
        kvsClient.getSignalingChannelEndpoint(signalingEndpointInput!).continueWith(block: { (task) -> Void in
            if task.error == nil {
                for endpoint in task.result!.resourceEndpointList! {
                    switch endpoint.protocols {
                    case .https:
                        endpoints["HTTPS"] = endpoint.resourceEndpoint
                    case .wss:
                        endpoints["WSS"] = endpoint.resourceEndpoint
                    case .webrtc:
                        endpoints["WEBRTC"] = endpoint.resourceEndpoint
                    case .unknown:
                        print("Error: Unknown endpoint protocol ", endpoint.protocols, "for endpoint" + endpoint.description())
                    }
                }
            }
        }).waitUntilFinished()
        return endpoints
    }

    private func getIceCandidates(channelARN: String, endpoint: AWSEndpoint?, regionType: AWSRegionType, clientId: String) -> [RTCIceServer] {
        var RTCIceServersList = [RTCIceServer]()
        let kvsStunUrlStrings = ["stun:stun.kinesisvideo.\(regionType.rawValue).amazonaws.com:443"]
        
        guard let endpoint = endpoint else { return [] }
        let configuration = AWSServiceConfiguration(region: regionType,
                                                  endpoint: endpoint,
                                                  credentialsProvider: ESPAssumeRoleCredentialsProvider.shared)
        guard let config = configuration else { return [] }
        AWSKinesisVideoSignaling.register(with: config, forKey: ESPAWSConstants.awsKinesisVideoKey)
        let kvsSignalingClient = AWSKinesisVideoSignaling(forKey: ESPAWSConstants.awsKinesisVideoKey)
        
        let iceServerConfigRequest = AWSKinesisVideoSignalingGetIceServerConfigRequest.init()
        iceServerConfigRequest?.channelARN = channelARN
        iceServerConfigRequest?.clientId = clientId
        
        kvsSignalingClient.getIceServerConfig(iceServerConfigRequest!).continueWith(block: { (task) -> Void in
            if let error = task.error {
                print("Error to get ice server config: \(error)")
            } else {
                print("ICE Server List: ", task.result!.iceServerList!)
                
                for iceServer in task.result!.iceServerList! {
                    RTCIceServersList.append(RTCIceServer(urlStrings: iceServer.uris!,
                                                        username: iceServer.username,
                                                        credential: iceServer.password))
                }
                
                RTCIceServersList.append(RTCIceServer(urlStrings: kvsStunUrlStrings))
            }
        }).waitUntilFinished()
        return RTCIceServersList
    }
    
    private func createSignedWSSUrl(channelARN: String, region: String, wssEndpoint: String?, isMaster: Bool, clientId: String) -> URL? {
        var AWSCredentials: AWSCredentials?
        
        // Use ESPAssumeRoleCredentialsProvider to get credentials
        let task = ESPAssumeRoleCredentialsProvider.shared.credentials()
        task.waitUntilFinished()
        
        if let error = task.error {
            print("Error getting credentials: \(error)")
            return nil
        }
        
        AWSCredentials = task.result
        
        guard let credentials = AWSCredentials else {
            print("No credentials available")
            return nil
        }
        
        guard let wssEndpoint = wssEndpoint else { return nil }
        
        var httpUrlString = wssEndpoint
            + "?X-Amz-ChannelARN=" + channelARN
        if !isMaster {
            httpUrlString += "&X-Amz-ClientId=" + clientId
        }
        
        guard let httpRequestURL = URL(string: httpUrlString),
              let wssRequestURL = URL(string: wssEndpoint) else {
            return nil
        }
        
        let wssURL = KVSSigner.sign(
            signRequest: httpRequestURL,
            secretKey: credentials.secretKey,
            accessKey: credentials.accessKey,
            sessionToken: credentials.sessionKey ?? "",
            wssRequest: wssRequestURL,
            region: region
        )
        return wssURL
    }

    /// Launch kinesis video
    func launchKinesisVideo(channel: String?) {
        if let neoChannel = self.channel {
            // Use new direct approach for faster video launch
            self.launchESPVideoViewer(channel: neoChannel)
        }
    }
}

// MARK: - ESPVideoViewerDelegate
extension DeviceTraitListViewController: ESPVideoViewerDelegate {
    func videoViewerDidClose(_ viewer: ESPVideoViewController) {
        print("Video viewer closed")
        // Any cleanup if needed
    }
}

// MARK: - WebRTC and Signaling Delegates for new approach
extension DeviceTraitListViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate) {
        // This will be handled by ESPVideoViewController now
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        // This will be handled by ESPVideoViewController now
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        // This will be handled by ESPVideoViewController now
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveRemoteVideoTrack track: RTCVideoTrack) {
        // This will be handled by ESPVideoViewController now
    }
}

extension DeviceTraitListViewController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        // This will be handled by ESPVideoViewController now
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        // This will be handled by ESPVideoViewController now
    }
    
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        // This will be handled by ESPVideoViewController now
    }
    
    func signalClient(_ signalClient: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate) {
        // This will be handled by ESPVideoViewController now
    }
}
