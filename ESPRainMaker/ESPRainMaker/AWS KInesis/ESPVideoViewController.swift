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
//  ESPVideoViewController.swift
//  ESPRainMaker
//

import UIKit
import WebRTC
import AWSKinesisVideo
import AWSKinesisVideoSignaling
import AWSCore

protocol ESPVideoViewerDelegate: AnyObject {
    func videoViewerDidClose(_ viewer: ESPVideoViewController)
}

class ESPVideoViewController: UIViewController {
    
    // MARK: - Properties
    private let webRTCClient: WebRTCClient
    private let signalingClient: SignalingClient
    private let localSenderClientID: String
    private let isMaster: Bool
    private let channelName: String
    private var remoteSenderClientId: String? = ESPAWSConstants.connectAsViewClientId
    private var signalingConnected: Bool = false
    
    weak var delegate: ESPVideoViewerDelegate?
    
    private var remoteRenderer: RTCVideoRenderer?
    private var isVideoConnected = false
    private var connectionTimer: Timer?
    private var statsTimer: Timer?
    
    // Constraint for dynamic spacing between status view and close button
    private var statusViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let videoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusIcon: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let image = UIImage(systemName: "circle.fill", withConfiguration: config)
        imageView.image = image
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.text = "CONNECTING"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.0
        return view
    }()
    
    private let fpsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .white
        label.text = "FPS: --"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let qualityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .white
        label.text = "Quality: --"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.text = "Connecting to video stream..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    init(webRTCClient: WebRTCClient, signalingClient: SignalingClient, localSenderClientID: String, isMaster: Bool, channelName: String) {
        self.webRTCClient = webRTCClient
        self.signalingClient = signalingClient
        self.localSenderClientID = localSenderClientID
        self.isMaster = isMaster
        self.channelName = channelName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupVideoRenderer()
        startConnectionTimer()
        startStatsTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Keep app in portrait mode - video will be landscape within portrait container
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // No orientation changes needed
        
        // Cleanup
        connectionTimer?.invalidate()
        statsTimer?.invalidate()
        
        if isBeingDismissed {
            webRTCClient.shutdown()
            signalingClient.disconnect()
        }
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add elements directly to main view
        view.addSubview(closeButton) 
        view.addSubview(statusView)
        view.addSubview(fpsLabel)
        view.addSubview(loadingIndicator)
        
        // Status view elements
        statusView.addSubview(statusIcon)
        statusView.addSubview(statusLabel)
        
        loadingIndicator.startAnimating()
        
        // Rotate ALL UI elements by 90 degrees to match the rotated video
        closeButton.transform = CGAffineTransform(rotationAngle: .pi/2)
        statusView.transform = CGAffineTransform(rotationAngle: .pi/2)
        fpsLabel.transform = CGAffineTransform(rotationAngle: .pi/2)
    }
    
    private func setupConstraints() {
        // Create the dynamic constraint for status view spacing
        statusViewBottomConstraint = statusView.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -60)
        
        NSLayoutConstraint.activate([
            // Close button - positioned at TOP RIGHT of the rotated video view (user's perspective)  
            // Video's top-right = Device's bottom-right (position unchanged)
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Status view (LIVE) - positioned to the LEFT of close button from video viewer's perspective
            // Spacing will be adjusted dynamically based on status text
            statusViewBottomConstraint!,
            statusView.centerXAnchor.constraint(equalTo: closeButton.centerXAnchor),
            statusView.heightAnchor.constraint(equalToConstant: 32),
            
            // Status icon
            statusIcon.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            statusIcon.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 12),
            
            // Status label
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6),
            statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -12),
            
            // FPS label - positioned at BOTTOM LEFT of rotated video view (user's perspective)
            // Video's bottom-left = Device's top-left
            fpsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            fpsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            fpsLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Loading indicator - centered on screen
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add tap gesture to show/hide stats
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
    }
    
    private func setupVideoRenderer() {
        #if arch(arm64)
        // Using metal (arm64 only)
        let renderer = RTCMTLVideoView(frame: .zero)
        renderer.videoContentMode = .scaleAspectFit
        renderer.delegate = self
        #else
        // Using OpenGLES for the rest
        let renderer = RTCEAGLVideoView(frame: .zero)
        renderer.delegate = self
        #endif
        
        remoteRenderer = renderer
        
        // Add remote renderer to main VIEW (not container)
        view.addSubview(renderer)
        renderer.translatesAutoresizingMaskIntoConstraints = false
        view.sendSubviewToBack(renderer)
        
        // Center the renderer and make it fill the ENTIRE screen
        NSLayoutConstraint.activate([
            renderer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            renderer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            renderer.heightAnchor.constraint(equalTo: view.widthAnchor),  // Swapped due to rotation - EXACT same as VideoViewController
            renderer.widthAnchor.constraint(equalTo: view.heightAnchor)   // Swapped due to rotation - EXACT same as VideoViewController
        ])
        
        // Rotate the video view by 90 degrees
        renderer.transform = CGAffineTransform(rotationAngle: .pi/2)
        
        // Register the renderer with WebRTC client
        webRTCClient.renderRemoteVideo(to: renderer)
    }
    
    private func startConnectionTimer() {
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.handleConnectionTimeout()
        }
    }
    
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        webRTCClient.shutdown()
        signalingClient.disconnect()
        delegate?.videoViewerDidClose(self)
        dismiss(animated: true)
    }
    
    @objc private func videoTapped() {
        UIView.animate(withDuration: 0.3) {
            self.statsView.alpha = self.statsView.alpha == 0.0 ? 1.0 : 0.0
        }
    }
    
    // MARK: - Video Handling
    func onRemoteVideoTrackReceived(_ track: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.hideLoadingView()
            self.updateConnectionStatus(.connected)
            self.isVideoConnected = true
            self.connectionTimer?.invalidate()
        }
    }
    
    private func hideLoadingView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.loadingView.alpha = 0.0
        }) { _ in
            self.loadingView.isHidden = true
            self.loadingIndicator.stopAnimating()
        }
    }
    
    private func handleConnectionTimeout() {
        DispatchQueue.main.async {
            self.updateConnectionStatus(.failed)
            self.loadingLabel.text = "Connection timeout. Please check your network."
        }
    }
    
    private func updateConnectionStatus(_ status: ConnectionStatus) {
        switch status {
        case .connecting:
            statusView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.9)
            statusLabel.text = "CONNECTING"
            // Use 60pt spacing for longer CONNECTING text
            statusViewBottomConstraint?.constant = -60
        case .connected:
            statusView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
            statusLabel.text = "LIVE"
            // Use 20pt spacing for shorter LIVE text
            statusViewBottomConstraint?.constant = -20
        case .failed:
            statusView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
            statusLabel.text = "FAILED"
            // Use 30pt spacing for FAILED text
            statusViewBottomConstraint?.constant = -30
        }
        
        // Animate the constraint change for smooth transition
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateStats() {
        guard isVideoConnected else { return }
        
        webRTCClient.getStats { height, width in
            DispatchQueue.main.async {
                self.qualityLabel.text = "Quality: \(Int(width))×\(Int(height))"
            }
        } fpsCompletion: { fps in
            DispatchQueue.main.async {
                self.fpsLabel.text = "FPS: \(Int(fps))"
            }
        }
    }
    
    // Helper method for setting remote sender client ID
    private func setRemoteSenderClientId() {
        if self.remoteSenderClientId == nil {
            remoteSenderClientId = ESPAWSConstants.connectAsViewClientId
        }
    }
    
    // Helper method for sending answer
    private func sendAnswer(recipientClientID: String) {
        webRTCClient.answer { [weak self] localSdp in
            guard let self = self else { return }
            self.signalingClient.sendAnswer(rtcSdp: localSdp, recipientClientId: recipientClientID)
            self.webRTCClient.updatePeerConnectionAndHandleIceCandidates(clientId: recipientClientID)
        }
    }
}

// MARK: - RTCVideoViewDelegate
extension ESPVideoViewController: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        DispatchQueue.main.async {
            self.hideLoadingView()
            self.updateConnectionStatus(.connected)
            self.isVideoConnected = true
            self.connectionTimer?.invalidate()
        }
    }
}

// MARK: - WebRTCClientDelegate
extension ESPVideoViewController: WebRTCClientDelegate {
    func webRTCClient(_: WebRTCClient, didGenerate candidate: RTCIceCandidate) {
        self.setRemoteSenderClientId()
        signalingClient.sendIceCandidate(rtcIceCandidate: candidate,
                                        master: isMaster,
                                        recipientClientId: remoteSenderClientId ?? "",
                                        senderClientId: localSenderClientID)
    }

    func webRTCClient(_: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected, .completed:
                self.updateConnectionStatus(.connected)
                self.hideLoadingView()
                self.connectionTimer?.invalidate()
            case .disconnected:
                self.updateConnectionStatus(.failed)
            case .new:
                self.updateConnectionStatus(.connecting)
            case .checking:
                self.updateConnectionStatus(.connecting)
            case .failed:
                self.updateConnectionStatus(.failed)
                self.loadingLabel.text = "Connection failed. Please try again."
            case .closed, .count:
                break
            @unknown default:
                break
            }
        }
    }

    func webRTCClient(_: WebRTCClient, didReceiveData _: Data) {
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveRemoteVideoTrack track: RTCVideoTrack) {
        DispatchQueue.main.async {
            self.onRemoteVideoTrackReceived(track)
        }
    }
}

// MARK: - SignalClientDelegate
extension ESPVideoViewController: SignalClientDelegate {
    func signalClientDidConnect(_: SignalingClient) {
        signalingConnected = true
        
        DispatchQueue.main.async {
            self.updateConnectionStatus(.connecting)
        }
        
        // As viewer, send offer when connected
        webRTCClient.offer { [weak self] sdp in
            guard let self = self else { return }
            self.signalingClient.sendOffer(rtcSdp: sdp, senderClientid: self.localSenderClientID)
        }
    }

    func signalClientDidDisconnect(_: SignalingClient) {
        signalingConnected = false
        DispatchQueue.main.async {
            self.updateConnectionStatus(.failed)
            self.loadingLabel.text = "Signaling disconnected. Please try again."
        }
    }
    
    func signalClient(_: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient.set(remoteSdp: sdp, clientId: senderClientId) { [weak self] _ in
            if let self = self {
                self.sendAnswer(recipientClientID: self.remoteSenderClientId ?? "")
            }
        }
    }

    func signalClient(_: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate) {
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient.set(remoteCandidate: candidate, clientId: senderClientId)
    }
}

// MARK: - Connection Status Enum
private enum ConnectionStatus {
    case connecting
    case connected
    case failed
} 
