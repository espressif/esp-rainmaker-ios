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
    // Use RainMaker user ID, fallback to constant if not available
    private var remoteSenderClientId: String? = ESPAWSConstants.connectAsViewClientId
    private var signalingConnected: Bool = false
    
    weak var delegate: ESPVideoViewerDelegate?
    
    private var remoteRenderer: RTCVideoRenderer?
    private var isVideoConnected = false
    private var connectionTimer: Timer?
    private var statsTimer: Timer?
    
    // Background/Foreground handling
    private var wasVideoConnectedBeforeBackground = false
    private var reconnectionTimer: Timer?
    private var maxReconnectionAttempts = 3
    private var currentReconnectionAttempts = 0
    private var backgroundEnteredAt: Date?
    private var isReconnecting = false // Flag to prevent concurrent reconnection attempts
    private var consecutiveZeroFpsCount = 0 // Track consecutive zero FPS readings
    
    // Constraint for dynamic spacing between status view and close button
    private var statusViewBottomConstraint: NSLayoutConstraint?
    
    // Detailed stats tracking for diagnostics (matching Android implementation)
    private var lastFramesDropped: Int64 = 0
    private var lastStatsTime: TimeInterval = 0
    private var streamStartTime: TimeInterval = 0
    private var isStreamActive = false
    
    // Current stats values for diagnostics display
    private var currentFps: Double = 0
    private var receivedFps: Double = 0
    private var droppedFps: Double = 0
    private var totalFramesDropped: Int64 = 0
    private var totalBytesReceived: Int64 = 0
    private var totalPacketsReceived: Int64 = 0
    private var totalPacketsLost: Int64 = 0
    private var jitterMs: Double = 0
    private var videoCodec: String = "N/A"
    private var currentFrameWidth: Int = 0
    private var currentFrameHeight: Int = 0
    
    // Diagnostics view
    private var diagnosticsOverlay: UIView?
    private var diagnosticsUpdateTimer: Timer?
    
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
        setupBackgroundForegroundHandling()
        startConnectionTimer()
        startStatsTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Keep app in portrait mode - video will be landscape within portrait container
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Add long press gesture after view is fully laid out
        setupLongPressGesture()
    }
    
    private func setupLongPressGesture() {
        // Remove any existing gesture recognizer first
        if let existingGesture = view.gestureRecognizers?.first(where: { $0 is UILongPressGestureRecognizer }) {
            view.removeGestureRecognizer(existingGesture)
        }
        
        // Add long press gesture directly to the main view
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(videoLongPressed(_:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.numberOfTouchesRequired = 1
        longPressGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false // Don't cancel button touches
        view.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // No orientation changes needed
        
        // Cleanup
        connectionTimer?.invalidate()
        statsTimer?.invalidate()
        reconnectionTimer?.invalidate()
        diagnosticsUpdateTimer?.invalidate()
        diagnosticsOverlay?.removeFromSuperview()
        
        if isBeingDismissed {
            webRTCClient.shutdown()
            signalingClient.disconnect()
            removeBackgroundForegroundObservers()
        }
    }
    
    deinit {
        removeBackgroundForegroundObservers()
        reconnectionTimer?.invalidate()
    }
    
    // MARK: - Background/Foreground Handling
    private func setupBackgroundForegroundHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func removeBackgroundForegroundObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        wasVideoConnectedBeforeBackground = isVideoConnected
        backgroundEnteredAt = Date()
        
        // Mark video as potentially disconnected since background may break the stream
        // We'll verify and reconnect when coming back to foreground
        isVideoConnected = false
        
        // Don't shutdown connections immediately - let them try to survive
        // iOS will handle the actual suspension
    }
    
    @objc private func appDidBecomeActive() {
        // CRITICAL: Always invalidate any existing reconnection timer from previous cycles
        // This prevents stale timers from interfering with new reconnection attempts
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        
        var wasLongBackground = false
        if let bgAt = backgroundEnteredAt {
            let elapsed = Date().timeIntervalSince(bgAt)
            // Over ~60s in background likely invalidates sockets; treat as long background
            wasLongBackground = elapsed > 60
        }
        
        // Always reset video connection flag when coming back from background
        // We'll verify actual video flow via FPS/stats
        if wasLongBackground {
            isVideoConnected = false
        }
        
        // CRITICAL: Always reset reconnection state when coming back from background
        // This ensures clean state for each background/foreground cycle
        currentReconnectionAttempts = 0
        isReconnecting = false
        consecutiveZeroFpsCount = 0
        
        // Reconnect if background lasted long, or if we were connected before but lost connection
        let shouldReconnect = wasLongBackground || (wasVideoConnectedBeforeBackground && (!signalingConnected || !isVideoConnected))
        if shouldReconnect {
            // Small delay to let app/UI/network settle after activation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.attemptReconnection()
            }
        } else if wasVideoConnectedBeforeBackground {
            // Even if we don't need to reconnect, verify video is actually flowing
            // Check after a short delay to see if FPS is updating
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                // If we think we're connected but video isn't flowing, trigger reconnection
                if self.isVideoConnected && !self.isReconnecting {
                    // We'll check this in the next stats update - if FPS is 0, we'll know
                }
            }
        }
    }
    
    private func attemptReconnection() {
        // Prevent concurrent reconnection attempts
        guard !isReconnecting else {
            return
        }
        
        guard currentReconnectionAttempts < maxReconnectionAttempts else {
            isReconnecting = false
            // CRITICAL: Invalidate timer when max attempts reached
            reconnectionTimer?.invalidate()
            reconnectionTimer = nil
            DispatchQueue.main.async {
                self.updateConnectionStatus(.failed)
                self.loadingLabel.text = "Connection lost. Please restart video."
            }
            return
        }
        
        // CRITICAL: Invalidate any existing reconnection timer before starting new attempt
        // This prevents multiple timers from running simultaneously
        reconnectionTimer?.invalidate()
        
        isReconnecting = true
        currentReconnectionAttempts += 1
        // Reset video connection flag - we'll set it to true only when video actually arrives
        isVideoConnected = false
        consecutiveZeroFpsCount = 0 // Reset FPS counter
        
        DispatchQueue.main.async {
            self.updateConnectionStatus(.connecting)
            self.loadingLabel.text = "Reconnecting to video stream..."
        }
        
        // Always force a clean signaling reconnect to avoid stale sockets
        signalingClient.disconnect()
        
        // Wait a bit before reconnecting to ensure clean disconnect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.signalingClient.connect()
        }
        
        // Set up a timer to check if reconnection was successful
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.checkReconnectionStatus()
        }
    }
    
    private func checkReconnectionStatus() {
        // CRITICAL: Invalidate timer before processing to prevent it from firing again
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        
        if isVideoConnected {
            currentReconnectionAttempts = 0
            isReconnecting = false
            DispatchQueue.main.async {
                self.updateConnectionStatus(.connected)
                self.hideLoadingView()
            }
        } else {
            isReconnecting = false // Reset flag before retrying
            attemptReconnection()
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
        
        // Enable user interaction for gesture recognizers
        renderer.isUserInteractionEnabled = true
        
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
    
    @objc private func videoLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { 
            return 
        }
        
        // Check if touch is on a button - if so, don't show diagnostics
        let location = gesture.location(in: view)
        let closeButtonFrame = closeButton.frame
        let statusViewFrame = statusView.frame
        
        // Check if touch is within button bounds
        if closeButtonFrame.contains(location) {
            return
        }
        
        if statusViewFrame.contains(location) {
            return
        }
        
        showDetailedStats()
    }
    
    // MARK: - Video Handling
    func onRemoteVideoTrackReceived(_ track: RTCVideoTrack) {
        DispatchQueue.main.async {
            // Don't set isVideoConnected = true here - wait for actual video frames (FPS > 0)
            // This prevents false positives when video track exists but no frames are flowing
            // The FPS check in updateStats will set isVideoConnected when frames actually arrive
            self.connectionTimer?.invalidate()
            // Keep status as connecting until we verify frames are flowing
            if !self.isVideoConnected {
                self.updateConnectionStatus(.connecting)
                self.loadingLabel.text = "Waiting for video stream..."
            }
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
        webRTCClient.getStats { height, width in
            DispatchQueue.main.async {
                self.qualityLabel.text = "Quality: \(Int(width))×\(Int(height))"
            }
        } fpsCompletion: { fps in
            DispatchQueue.main.async {
                self.fpsLabel.text = "FPS: \(Int(fps))"
                // If frames are flowing, mark as connected
                if fps > 0 {
                    self.consecutiveZeroFpsCount = 0 // Reset counter
                    
                    // Only mark as connected when we actually receive video frames
                    if !self.isVideoConnected {
                        self.isVideoConnected = true
                        self.isReconnecting = false // Clear reconnection flag when video actually flows
                        self.currentReconnectionAttempts = 0
                        
                        // Start stream duration tracking when video actually flows
                        if !self.isStreamActive {
                            self.streamStartTime = Date().timeIntervalSince1970 * 1000 // milliseconds
                            self.isStreamActive = true
                        }
                    }
                    
                    // Always update status to connected when video is flowing
                    if self.statusLabel.text != "LIVE" {
                        self.updateConnectionStatus(.connected)
                        self.hideLoadingView()
                        self.connectionTimer?.invalidate()
                    }
                } else {
                    // If FPS is 0, increment counter
                    if self.isVideoConnected && !self.isReconnecting {
                        self.consecutiveZeroFpsCount += 1
                        
                        // If we've had 0 FPS for 2 consecutive stats updates (~2 seconds), video is likely dead
                        // Reduced from 3 to 2 for faster detection
                        if self.consecutiveZeroFpsCount >= 2 {
                            self.isVideoConnected = false
                            self.consecutiveZeroFpsCount = 0
                            // Trigger reconnection if we're active
                            if UIApplication.shared.applicationState == .active {
                                self.attemptReconnection()
                            }
                        }
                    } else if !self.isVideoConnected && !self.isReconnecting && self.statusLabel.text == "LIVE" {
                        // If status shows LIVE but we're not connected and FPS is 0, we're in a bad state
                        // This handles the case where status got stuck on LIVE
                        self.consecutiveZeroFpsCount += 1
                        if self.consecutiveZeroFpsCount >= 2 {
                            self.consecutiveZeroFpsCount = 0
                            self.updateConnectionStatus(.connecting)
                            if UIApplication.shared.applicationState == .active {
                                self.attemptReconnection()
                            }
                        }
                    }
                }
            }
        }
        
        // Also collect detailed stats for diagnostics (matching Android)
        webRTCClient.getDetailedStats { [weak self] stats in
            guard let self = self else { return }
            
            let currentTime = Date().timeIntervalSince1970 * 1000 // milliseconds
            
            // Calculate dropped FPS (delta calculation matching Android)
            var calcDroppedFps: Double = 0
            if self.lastStatsTime > 0 && currentTime > self.lastStatsTime {
                let deltaSeconds = (currentTime - self.lastStatsTime) / 1000.0
                let deltaFramesDropped = stats.totalFramesDropped - self.lastFramesDropped
                if deltaSeconds > 0 && deltaFramesDropped >= 0 {
                    calcDroppedFps = Double(deltaFramesDropped) / deltaSeconds
                }
            }
            
            // Calculate received FPS = Current FPS + Dropped FPS (matching Android)
            let calcReceivedFps = stats.currentFps + calcDroppedFps
            
            // Update tracking variables
            DispatchQueue.main.async {
                self.currentFps = stats.currentFps
                self.receivedFps = calcReceivedFps
                self.droppedFps = calcDroppedFps
                self.totalFramesDropped = stats.totalFramesDropped
                self.totalBytesReceived = stats.totalBytesReceived
                self.totalPacketsReceived = stats.totalPacketsReceived
                self.totalPacketsLost = stats.totalPacketsLost
                self.jitterMs = stats.jitterMs
                self.videoCodec = stats.videoCodec
                self.currentFrameWidth = stats.currentFrameWidth
                self.currentFrameHeight = stats.currentFrameHeight
                
                self.lastFramesDropped = stats.totalFramesDropped
                self.lastStatsTime = currentTime
                
                // Update diagnostics view if visible
                if let container = self.diagnosticsOverlay {
                    // Find stats container in the view hierarchy
                    if let statsContainer = container.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                        // Clear existing stats (except title)
                        statsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
                        self.updateStatsContent(statsContainer: statsContainer)
                    }
                }
            }
        }
    }
    
    // MARK: - Diagnostics View (matching Android implementation)
    private func showDetailedStats() {
        // Remove existing overlay if any
        diagnosticsOverlay?.removeFromSuperview()
        diagnosticsUpdateTimer?.invalidate()
        
        // Create container view matching Android design
        let container = UIView()
        container.backgroundColor = UIColor(white: 0, alpha: 0.6) // #99000000 equivalent
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = true
        
        // Add padding (8dp equivalent)
        let padding: CGFloat = 8 * (UIScreen.main.bounds.width / 375.0) // Scale based on screen size
        
        // Create title
        let titleLabel = UILabel()
        titleLabel.text = "Video Statistics"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Create stats container
        let statsContainer = UIStackView()
        statsContainer.axis = .vertical
        statsContainer.spacing = 4
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statsContainer)
        
        // Store reference for updates
        diagnosticsOverlay = container
        
        // Add to view FIRST
        view.addSubview(container)
        
        // Position and rotate diagnostics to match video coordinate system
        // All UI elements (closeButton, statusView, fpsLabel) are rotated 90° clockwise
        // fpsLabel: device top-left, rotated 90° → video's visual bottom-left
        // closeButton: device bottom-right, rotated 90° → video's visual top-right
        // Diagnostics: should be at video's visual top-left
        // 
        // Since fpsLabel (device top-left, rotated) = video bottom-left,
        // then video's visual top-left = device bottom-left (rotated)
        let margin: CGFloat = 16 * (UIScreen.main.bounds.width / 375.0)
        
        NSLayoutConstraint.activate([
            // Position at device bottom-left (will become video's visual top-left after rotation)
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(margin + 20)),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margin),

            // Width becomes visual height after rotation
            container.widthAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -padding),
            
            statsContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),
            statsContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            statsContainer.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -padding),
            statsContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        ])
        
        // Update stats content BEFORE layout
        updateStatsContent(statsContainer: statsContainer)
        
        // Force layout to calculate actual size
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Rotate 90° clockwise to match other UI elements and video coordinate system
        container.transform = CGAffineTransform(rotationAngle: .pi/2)
        
        // Bring to front AFTER everything is set up
        view.bringSubviewToFront(container)
        
        // Make absolutely sure it's visible
        container.alpha = 1.0
        container.isHidden = false
        
        // Set up periodic updates (every 1 second matching Android)
        diagnosticsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let container = self.diagnosticsOverlay else { return }
            // Find stats container in the view hierarchy
            if let statsContainer = container.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                // Clear ALL arranged subviews (sections) before re-adding
                // This prevents duplication
                while !statsContainer.arrangedSubviews.isEmpty {
                    statsContainer.arrangedSubviews.first?.removeFromSuperview()
                }
                // Re-add stats content
                self.updateStatsContent(statsContainer: statsContainer)
            }
        }
        
        // Add tap gesture to dismiss on the MAIN VIEW (not just container)
        // This allows dismissing by tapping anywhere on screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDiagnosticsOnTap(_:)))
        tapGesture.cancelsTouchesInView = false // Don't interfere with other gestures
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissDiagnosticsOnTap(_ gesture: UITapGestureRecognizer) {
        // Dismiss on any tap anywhere on screen
        let location = gesture.location(in: view)
        
        // If tap is on the diagnostics overlay itself, still dismiss
        // (This allows dismissing by tapping the overlay or anywhere else)
        if let overlay = diagnosticsOverlay, overlay.frame.contains(location) {
            dismissDiagnostics()
        } else {
            // Tap is outside overlay, dismiss
            dismissDiagnostics()
        }
    }
    
    private func dismissDiagnostics() {
        diagnosticsOverlay?.removeFromSuperview()
        diagnosticsOverlay = nil
        diagnosticsUpdateTimer?.invalidate()
        diagnosticsUpdateTimer = nil
        
        // Remove the tap gesture from view
        if let tapGesture = view.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer && ($0 as? UITapGestureRecognizer)?.numberOfTapsRequired == 1 }) {
            view.removeGestureRecognizer(tapGesture)
        }
    }
    
    private func updateStatsContent(statsContainer: UIStackView) {
        // Calculate bitrate (matching Android calculation)
        let bitrate: Int64
        if isStreamActive && streamStartTime > 0 {
            let durationSeconds = (Date().timeIntervalSince1970 * 1000 - streamStartTime) / 1000.0
            if durationSeconds > 0 {
                bitrate = (totalBytesReceived * 8) / Int64(durationSeconds) / 1000 // kbps
            } else {
                bitrate = 0
            }
        } else {
            bitrate = 0
        }
        
        // Calculate packet loss percentage (matching Android)
        let totalPackets = totalPacketsReceived + totalPacketsLost
        let packetLossPercent: Double
        if totalPackets > 0 {
            packetLossPercent = (Double(totalPacketsLost) * 100.0) / Double(totalPackets)
        } else {
            packetLossPercent = 0
        }
        
        // Format bytes to MB (matching Android)
        let bytesReceivedMB = Double(totalBytesReceived) / (1024.0 * 1024.0)
        
        // VIDEO Section
        addStatsSection(to: statsContainer, sectionTitle: "VIDEO", labels: [
            "Resolution", "Current FPS", "Received FPS", "Dropped FPS", "Frames Dropped", "Codec"
        ], values: [
            "\(currentFrameWidth) x \(currentFrameHeight)",
            String(format: "%.1f", currentFps),
            String(format: "%.1f", receivedFps),
            String(format: "%.1f", droppedFps),
            "\(totalFramesDropped)",
            videoCodec
        ])
        
        // NETWORK Section
        addStatsSection(to: statsContainer, sectionTitle: "NETWORK", labels: [
            "Bitrate", "Total Data", "Packets RX", "Packets Lost", "Loss %", "Jitter"
        ], values: [
            "\(bitrate) kbps",
            String(format: "%.2f MB", bytesReceivedMB),
            "\(totalPacketsReceived)",
            "\(totalPacketsLost)",
            String(format: "%.2f%%", packetLossPercent),
            String(format: "%.2f ms", jitterMs)
        ])
    }
    
    private func addStatsSection(to container: UIStackView, sectionTitle: String, labels: [String], values: [String]) {
        // Section title
        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = sectionTitle
        sectionTitleLabel.textColor = UIColor(white: 0.67, alpha: 1.0) // #AAAAAA equivalent
        sectionTitleLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        container.addArrangedSubview(sectionTitleLabel)
        
        // Create rows with two columns (matching Android layout)
        let itemsPerRow = 2
        for i in stride(from: 0, to: labels.count, by: itemsPerRow) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            
            // First column
            if i < labels.count {
                row.addArrangedSubview(createStatItem(label: labels[i], value: values[i]))
            }
            
            // Second column
            if i + 1 < labels.count {
                row.addArrangedSubview(createStatItem(label: labels[i + 1], value: values[i + 1]))
            }
            
            container.addArrangedSubview(row)
        }
    }
    
    private func createStatItem(label: String, value: String) -> UIView {
        let item = UIStackView()
        item.axis = .vertical
        item.spacing = 2
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = UIColor(white: 0.73, alpha: 1.0) // #BBBBBB equivalent
        labelView.font = UIFont.systemFont(ofSize: 9)
        
        let valueView = UILabel()
        valueView.text = value
        valueView.textColor = .white
        valueView.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        
        item.addArrangedSubview(labelView)
        item.addArrangedSubview(valueView)
        
        return item
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
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {}
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
                // Don't set isVideoConnected = true here - wait for actual video frames
                // This prevents showing "connected" when connection is established but video isn't flowing
                self.connectionTimer?.invalidate()
                self.currentReconnectionAttempts = 0 // Reset reconnection attempts
                self.isReconnecting = false // Reset reconnection flag
                
                // CRITICAL: Cancel any pending reconnection timer and clean up
                self.reconnectionTimer?.invalidate()
                self.reconnectionTimer = nil
                
                // Set status to connecting until we verify video is actually flowing
                // The FPS check will update to connected when video actually arrives
                if !self.isVideoConnected {
                    self.updateConnectionStatus(.connecting)
                    self.loadingLabel.text = "Waiting for video stream..."
                }
                
                // Start stream duration tracking only when video actually flows (handled in FPS check)
            case .disconnected:
                // Always mark video as disconnected when WebRTC disconnects
                self.isVideoConnected = false
                self.consecutiveZeroFpsCount = 0
                
                // If not already reconnecting, trigger reconnection immediately
                if !self.isReconnecting && UIApplication.shared.applicationState == .active {
                    self.attemptReconnection()
                } else if self.currentReconnectionAttempts == 0 {
                    self.updateConnectionStatus(.failed)
                }
            case .new:
                // Reset video connection flag when starting new connection
                self.isVideoConnected = false
                // Don't override status if we're reconnecting
                if self.currentReconnectionAttempts == 0 {
                    self.updateConnectionStatus(.connecting)
                }
            case .checking:
                // Don't mark as connected yet - wait for actual connection
                self.updateConnectionStatus(.connecting)
            case .failed:
                // Always mark video as disconnected on failure
                self.isVideoConnected = false
                self.consecutiveZeroFpsCount = 0
                
                // If not already reconnecting, trigger reconnection
                if !self.isReconnecting && UIApplication.shared.applicationState == .active {
                    self.attemptReconnection()
                } else if self.currentReconnectionAttempts == 0 {
                    self.updateConnectionStatus(.failed)
                    self.loadingLabel.text = "Connection failed. Please try again."
                } else {
                    // During reconnection, keep showing connecting status
                    self.updateConnectionStatus(.connecting)
                    self.loadingLabel.text = "Reconnecting to video stream..."
                }
            case .closed:
                // Mark as disconnected when connection is closed
                self.isVideoConnected = false
                self.consecutiveZeroFpsCount = 0
            case .count:
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
        
        // CRITICAL: Cancel any pending reconnection timer since we're now connected
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }

    func signalClientDidDisconnect(_: SignalingClient) {
        signalingConnected = false
        // Don't show failed status or trigger reconnection if we're already reconnecting
        // (disconnect is expected during reconnect)
        if !isReconnecting {
            DispatchQueue.main.async {
                self.updateConnectionStatus(.failed)
                self.loadingLabel.text = "Signaling disconnected. Please try again."
            }
            // If we're active, proactively attempt reconnection
            if UIApplication.shared.applicationState == .active {
                attemptReconnection()
            }
        } else {
            // Signaling disconnected during reconnection (expected)
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

// MARK: - UIGestureRecognizerDelegate
extension ESPVideoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow long press to work alongside other gestures
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Always receive the touch - we'll check button bounds in the handler
        // This ensures the gesture recognizer gets a chance to recognize
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't require failure of button gestures - we want to work alongside them
        return false
    }
}

// MARK: - Connection Status Enum
private enum ConnectionStatus {
    case connecting
    case connected
    case failed
} 
