// Copyright 2026 Espressif Systems (Shanghai) PTE LTD
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
//  OnNetworkDiscoveryViewController.swift
//  ESPRainMaker
//

import UIKit

class OnNetworkDiscoveryViewController: UIViewController {
    
    // Custom navigation bar elements
    private let topBarView: TopBarView
    private let topBarTitle: BarTitle
    private let backButton: BarButton
    
    // Programmatic UI elements
    private let tableView: UITableView
    private let loadingIndicator: UIActivityIndicatorView
    private let emptyStateView: UIView
    private let emptyStateImageView: UIImageView
    private let emptyStateLabel: UILabel
    
    private var deviceList: [ESPOnNetworkDevice] = []
    private var discovery: ESPChallengeRespServiceDiscovery?
    private var discoveryTimeout: Timer?
    private let discoveryTimeoutInterval: TimeInterval = 10.0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // Initialize UI elements programmatically
        topBarView = TopBarView()
        topBarTitle = BarTitle()
        backButton = BarButton()
        tableView = UITableView()
        loadingIndicator = UIActivityIndicatorView(style: .large)
        emptyStateView = UIView()
        emptyStateImageView = UIImageView()
        emptyStateLabel = UILabel()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        // Initialize UI elements programmatically
        topBarView = TopBarView()
        topBarTitle = BarTitle()
        backButton = BarButton()
        tableView = UITableView()
        loadingIndicator = UIActivityIndicatorView(style: .large)
        emptyStateView = UIView()
        emptyStateImageView = UIImageView()
        emptyStateLabel = UILabel()
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        startDiscovery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide standard navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDiscovery()
    }
    
    deinit {
        stopDiscovery()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup custom navigation bar
        setupCustomNavigationBar()
        
        // Configure loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Configure table view - positioned below TopBarView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Configure empty state view (icon + bold label centered on screen)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.image = UIImage(named: "no_device_icon")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateView.addSubview(emptyStateImageView)
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "No devices found"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        emptyStateView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 170),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 170),
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func setupCustomNavigationBar() {
        // Configure TopBarView
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBarView)
        
        // Configure back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        topBarView.addSubview(backButton)
        
        // Configure title label
        topBarTitle.translatesAutoresizingMaskIntoConstraints = false
        topBarTitle.text = "On Network Discovery"
        topBarTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        topBarTitle.textAlignment = .center
        topBarView.addSubview(topBarTitle)
        
        // Set up constraints for TopBarView
        NSLayoutConstraint.activate([
            // TopBarView constraints
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 96),
            
            // Title constraints - centered horizontally, bottom aligned (matching Add Device screen)
            topBarTitle.centerXAnchor.constraint(equalTo: topBarView.centerXAnchor),
            topBarTitle.bottomAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: -14),
            
            // Back button constraints - centerY aligned with title (matching Add Device screen)
            backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 60),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            backButton.centerYAnchor.constraint(equalTo: topBarTitle.centerYAnchor)
        ])
        
        // Bring TopBarView to front
        view.bringSubviewToFront(topBarView)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none // Match ESPFabricCell style - no separators between cards
        tableView.backgroundColor = .systemGroupedBackground // Match typical table view background
        tableView.register(
            OnNetworkDeviceTableViewCell.self,
            forCellReuseIdentifier: OnNetworkDeviceTableViewCell.reuseIdentifier
        )
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func startDiscovery() {
        deviceList.removeAll()
        tableView.reloadData()
        emptyStateView.isHidden = true
        // Ensure loader is above table view so it is visible while searching
        view.bringSubviewToFront(loadingIndicator)
        view.bringSubviewToFront(topBarView)
        loadingIndicator.startAnimating()
        
        discovery = ESPChallengeRespServiceDiscovery(
            serviceType: Constants.challengeRespServiceType,
            domain: Constants.serviceDomain,
            delegate: self
        )
        
        discovery?.startDiscovery()
        
        // Set timeout
        discoveryTimeout = Timer.scheduledTimer(
            timeInterval: discoveryTimeoutInterval,
            target: self,
            selector: #selector(discoveryTimeoutFired),
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopDiscovery() {
        discoveryTimeout?.invalidate()
        discoveryTimeout = nil
        discovery?.stopDiscovery()
        discovery = nil
    }
    
    @objc private func discoveryTimeoutFired() {
        stopDiscovery()
        loadingIndicator.stopAnimating()
        
        if deviceList.isEmpty {
            emptyStateView.isHidden = false
        }
    }
    
    private func handleDeviceSelection(_ device: ESPOnNetworkDevice) {
        if device.popRequired {
            presentConnectVCForPOP(device: device)
        } else {
            navigateToProvisioning(device: device, pop: nil)
        }
    }

    /// Pushes the app's existing Connect (POP) screen; on submit, pops it and continues to Success/provisioning.
    private func presentConnectVCForPOP(device: ESPOnNetworkDevice) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let connectVC = mainStoryboard.instantiateViewController(withIdentifier: Constants.connectVCIdentifier) as? ConnectViewController else {
            return
        }
        connectVC.onNetworkDevice = device
        connectVC.onNetworkPOPCompletion = { [weak self] pop in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: false)
            self.navigateToProvisioning(device: device, pop: pop)
        }
        navigationController?.pushViewController(connectVC, animated: true)
    }

    private func navigateToProvisioning(device: ESPOnNetworkDevice, pop: String?) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let successVC = mainStoryboard.instantiateViewController(withIdentifier: "successViewController") as? SuccessViewController else {
            return
        }
        
        successVC.isOnNetworkFlow = true
        successVC.onNetworkDevice = device
        successVC.pop = pop
        
        navigationController?.pushViewController(successVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension OnNetworkDiscoveryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: OnNetworkDeviceTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! OnNetworkDeviceTableViewCell
        
        let device = deviceList[indexPath.row]
        cell.configure(with: device)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension OnNetworkDiscoveryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = deviceList[indexPath.row]
        handleDeviceSelection(device)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Dynamic height calculation similar to ESPFabricCell
        guard indexPath.row < deviceList.count else {
            return 80.0 // Minimum height
        }
        
        let device = deviceList[indexPath.row]
        
        // Calculate width available for text: table width - container margins (20*2) - label padding (20*2)
        let textWidth = tableView.frame.width - 80.0
        
        // Calculate height for device name (service name)
        let nameHeight = device.serviceName.getViewHeight(labelWidth: textWidth, font: UIFont.systemFont(ofSize: 12.0, weight: .semibold))
        
        // Calculate height for device info (node ID)
        let infoHeight = device.nodeId.getViewHeight(labelWidth: textWidth, font: UIFont.systemFont(ofSize: 11.0, weight: .regular))
        
        // Base height: 10pt top margin + 20pt top padding + 4pt spacing + 20pt bottom padding + 10pt bottom margin = 64pt
        // Add calculated text heights
        let totalHeight = 64.0 + nameHeight + infoHeight
        
        // Return minimum 80pt (matching ESPFabricCell minimum)
        return max(80.0, totalHeight)
    }
}

// MARK: - ESPChallengeRespDiscoveryDelegate
extension OnNetworkDiscoveryViewController: ESPChallengeRespDiscoveryDelegate {
    func deviceFound(_ device: ESPOnNetworkDevice) {
        // Check if device already exists
        if deviceList.contains(where: { $0.nodeId == device.nodeId }) {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.deviceList.append(device)
            self.tableView.reloadData()
            
            // Hide loading if we have devices
            if !self.deviceList.isEmpty {
                self.loadingIndicator.stopAnimating()
                self.emptyStateView.isHidden = true
            }
        }
    }
}
