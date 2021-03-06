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

import AWSCognitoIdentityProvider
import UIKit

class ChangePasswordViewController: UIViewController {
    @IBOutlet var oldPasswordTextField: PasswordTextField!
    @IBOutlet var newPasswordTextField: PasswordTextField!
    @IBOutlet var confirmNewPasswordTextField: PasswordTextField!
    var pool: AWSCognitoIdentityUserPool?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
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
        let user = pool?.getUser(User.shared.userInfo.email)
        guard let oldPassword = oldPasswordTextField.text, !oldPassword.isEmpty else {
            showAlertWith(title: "Error", message: "Old password is required to change the password")
            return
        }

        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty else {
            showAlertWith(title: "Error", message: "New password is required to change the password")
            return
        }

        guard let confirmPasswordValue = confirmNewPasswordTextField.text, confirmPasswordValue == newPassword else {
            showAlertWith(title: "Error", message: "Re-entered password do not match.")
            return
        }
        Utility.showLoader(message: "", view: view)
        user?.changePassword(oldPassword, proposedPassword: newPassword).continueWith { [weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async {
                Utility.hideLoader(view: strongSelf.view)
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String ?? "",
                                                            message: error.userInfo["message"] as? String ?? "",
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        strongSelf.navigationController?.popToRootViewController(animated: false)
                    }
                    alertController.addAction(okAction)

                    strongSelf.present(alertController, animated: true, completion: nil)
                    return
                } else {
                    let alertController = UIAlertController(title: "Success",
                                                            message: "Password changed successfully",
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                        strongSelf.navigationController?.popToRootViewController(animated: false)
                    }
                    alertController.addAction(okAction)

                    strongSelf.present(alertController, animated: true, completion: nil)
                    return
                }
            }
            return nil
        }
    }

    func showAlertWith(title: String, message: String) {
        Utility.hideLoader(view: view)
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
        return
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
