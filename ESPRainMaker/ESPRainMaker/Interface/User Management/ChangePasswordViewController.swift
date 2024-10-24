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
//  ChangePasswordViewController.swift
//  ESPRainMaker
//

import UIKit

protocol UserPasswordUpdatedProtocol: NSObject {
    func logoutUser()
}

class ChangePasswordViewController: UIViewController {
    @IBOutlet var oldPasswordTextField: PasswordTextField!
    @IBOutlet var newPasswordTextField: PasswordTextField!
    @IBOutlet var confirmNewPasswordTextField: PasswordTextField!
    weak var userPasswordUpdatedDelegate: UserPasswordUpdatedProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @IBAction func backPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func setPassword(_: Any) {
        guard let oldPassword = oldPasswordTextField.text, !oldPassword.isEmpty else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error", message: "Old password is required to change the password", buttonTitle: "Retry") {}
            }
            return
        }

        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error", message: "New password is required to change the password", buttonTitle: "Retry") {}
            }
            return
        }

        guard let confirmPasswordValue = confirmNewPasswordTextField.text, confirmPasswordValue == newPassword else {
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.showErrorAlert(title: "Error", message: "Re-entered password do not match.", buttonTitle: "Retry") {}
            }
            return
        }
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        let service = ESPChangePasswordService(presenter: self)
        service.changePassword(oldPassword: oldPassword, newPassword: newPassword)
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case oldPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
        case newPasswordTextField:
            confirmNewPasswordTextField.becomeFirstResponder()
        case confirmNewPasswordTextField:
            confirmNewPasswordTextField.resignFirstResponder()
            setPassword(textField)
        default:
            return true
        }
        return true
    }
}

extension ChangePasswordViewController: ESPChangePasswordPresentationLogic {
    
    func passwordChanged(withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if let _ = error {
                self.handleError(error: error, buttonTitle: "Ok")
            } else {
                let alertController = UIAlertController(title: "Success",
                                                        message: "Password changed successfully",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    if let delegate = self.userPasswordUpdatedDelegate {
                        delegate.logoutUser()
                    } else {
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
