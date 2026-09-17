// Copyright 2020 Espressif Systems
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
//  DevicesCollectionViewCell.swift
//  ESPRainMaker
//

import UIKit

class DevicesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var bgView: UIView!
    var device: Device!
    var switchValue = false
    var switchActionButton: () -> Void = {}
    @IBOutlet var primaryValue: UILabel!
    @IBOutlet var deviceImageView: UIImageView!
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var switchButton: UIButton!
    @IBOutlet var triggerButton: UIButton!
    @IBOutlet var statusView: UIView!
    @IBOutlet var offlineLabel: UILabel!

    private lazy var bleLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: switchButton.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: switchButton.centerYAnchor)
        ])
        return indicator
    }()

    func updateBleLoadingState() {
        guard let nodeId = device?.node?.node_id else {
            bleLoadingIndicator.stopAnimating()
            switchButton.isHidden = false
            return
        }
        let loading = User.shared.bleLocalControl.isParamUpdateInProgress(nodeId: nodeId)
        if loading {
            bleLoadingIndicator.startAnimating()
            switchButton.isHidden = true
            triggerButton.isHidden = true
        } else {
            bleLoadingIndicator.stopAnimating()
        }
    }
    @IBAction func switchButtonPressed(_: Any) {
        let previousValue = switchValue
        switchValue = !switchValue
        updatePrimaryParamValue(switchValue)

        NetworkManager.shared.setDeviceParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [device.primary ?? "": switchValue]]) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    self.switchValue = previousValue
                    self.updatePrimaryParamValue(previousValue)
                    self.updateSwitchImage()
                    let view = self.parentViewController?.view ?? self.contentView
                    Utility.showToastMessage(view: view, message: "Fail to update parameter. Please check you network connection!!")
                case .success:
                    self.updateSwitchImage()
                    NotificationCenter.default.post(Notification(name: Notification.Name(Constants.reloadCollectionView)))
                default:
                    self.updateSwitchImage()
                    break
                }
            }
        }

        updateSwitchImage()
    }

    private func updatePrimaryParamValue(_ value: Bool) {
        guard let primaryName = device.primary,
              let params = device.params,
              let index = params.firstIndex(where: { $0.name == primaryName }) else { return }
        params[index].value = value
    }

    private func updateSwitchImage() {
        if switchValue {
            switchButton.setBackgroundImage(UIImage(named: "switch_on"), for: .normal)
        } else {
            switchButton.setBackgroundImage(UIImage(named: "switch_off"), for: .normal)
        }
    }
    
    @IBAction func triggerButtonPressed(_: Any) {
        // Animate button to show trigger effect
        triggerButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        UIView.animate(withDuration: 0.5,
          delay: 0,
                       usingSpringWithDamping: CGFloat(0.39),
                       initialSpringVelocity: CGFloat(0),
          options: .allowUserInteraction,
          animations: {
            self.triggerButton.transform = .identity
          }, completion: {_ in }
        )
        NetworkManager.shared.setDeviceParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [device.primary ?? "": true]]) { result in
            switch result {
            case .failure:
                let view = self.parentViewController?.view ?? self.contentView
                Utility.showToastMessage(view: view, message: "Fail to update parameter. Please check you network connection!!")
            default:
                break
            }
        }
    }

    func refresh() {
        device = nil
        switchValue = false
        primaryValue.text = ""
        deviceImageView.image = UIImage(named: Constants.dummyDeviceImage)
        deviceName.text = ""
        statusView.isHidden = true
        bleLoadingIndicator.stopAnimating()
    }
}
