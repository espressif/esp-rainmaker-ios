// Copyright 2023 Espressif Systems
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
//  ESPScannerViewController.swift
//  ESPRainMaker
//

import UIKit

class ESPScannerViewController: UIViewController {
    
    static let reuseIdentifier: String = "ESPScannerViewController"
    
    var param: Param!
    var device: Device!
    var attributeKey = ""
    var paramName: String = ""
    var code: String = ""
    
    @IBOutlet weak var scannerView: ESPQRScannerView! {
        didSet {
            scannerView.delegate = self
        }
    }
    
    @IBOutlet weak var qrCodeSenderView: UIView!
    @IBOutlet weak var qrCodeTextView: UITextView!
    @IBOutlet weak var qrCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.qrCodeTextField.delegate = self
        
        self.qrCodeSenderView.layer.borderWidth = 0.5
        self.qrCodeSenderView.layer.borderColor = UIColor.lightGray.cgColor
        
        self.qrCodeTextView.delegate = self
        self.qrCodeTextView.layer.borderWidth = 0.5
        self.qrCodeTextView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendQRCodeNoPressed(_ sender: Any) {
        self.code = ""
        self.qrCodeSenderView.isHidden = true
    }
    
    @IBAction func sendQRCodeYesPressed(_ sender: Any) {
        self.qrCodeSenderView.isHidden = true
        Utility.showLoader(message: "", view: self.view)
        DeviceControlHelper.shared.updateParam(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: self.code]], delegate: nil) { result in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.code = ""
                if result == .success {
                    self.alertUser(title: "Success", message: "Param updated successfully.", buttonTitle: "OK", callback: {
                        self.navigationController?.popViewController(animated: true)
                    })
                } else {
                    self.code = ""
                    DispatchQueue.main.async {
                        self.qrCodeSenderView.isHidden = true
                        Utility.hideLoader(view: self.view)
                        self.alertUser(title: "Failure", message: "Param update failed.", buttonTitle: "OK", callback: {
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func rescanPressed(_ sender: Any) {
        self.scannerView.startScanning()
        self.code = ""
    }
}

extension ESPScannerViewController: ESPQRScannerViewDelegate {
    
    func qrScanningDidStop() {}
    
    func qrScanningDidFail() {
        self.alertUser(title: "Failure", message: "Failed to scan QR code.", buttonTitle: "OK", callback: {})
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        if let code = str, code.count > 0 {
            self.qrCodeSenderView.isHidden = false
            self.view.bringSubviewToFront(self.qrCodeSenderView)
            self.qrCodeTextView.text = code
            self.code = code
        }
    }
}

extension ESPScannerViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
}

extension ESPScannerViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}
