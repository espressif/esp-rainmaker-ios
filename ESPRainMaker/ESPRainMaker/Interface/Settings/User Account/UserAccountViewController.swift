// Copyright 2021 Espressif Systems
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
//  UserAccountViewController.swift
//  ESPRainMaker
//

import Foundation
import UIKit

class UserAccountViewController: UIViewController, ESPNoRefreshTokenLogic {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var changePasswordView: UIView!
    @IBOutlet var changepasswordTopConstraint: NSLayoutConstraint!
    @IBOutlet var changepasswordHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailLabel.text = User.shared.userInfo.email
        userIDLabel.text = User.shared.userInfo.userID
        
        // Shows/hides change password option based on type of login.
        if User.shared.userInfo.loggedInWith == .other {
            changePasswordView.isHidden = true
            changepasswordHeightConstraint.constant = 0
            changepasswordTopConstraint.constant = 0
        } else {
            changePasswordView.isHidden = false
            changepasswordHeightConstraint.constant = 50.0
            changepasswordTopConstraint.constant = 20
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If change password segue is selected user pool update
        if segue.identifier == Constants.changePasswordSegueId {
            let vc = segue.destination as! ChangePasswordViewController
            vc.userPasswordUpdatedDelegate = self
        }
    }
}

extension UserAccountViewController: UserPasswordUpdatedProtocol {
    
    func logoutUser() {
        let service = ESPLogoutService(presenter: self)
        service.logoutUser()
    }
}

extension UserAccountViewController: ESPLogoutUserPresentationLogic {
    
    func userLoggedOut(withError error: ESPAPIError?) {
        self.clearUserData()
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.navigationController?.popToRootViewController(animated: false)
            self.tabBarController?.selectedIndex = 0
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let nav = storyboard.instantiateViewController(withIdentifier: "signInController") as? UINavigationController {
                if let _ = nav.viewControllers.first as? SignInViewController, let tab = self.tabBarController {
                    nav.modalPresentationStyle = .fullScreen
                    tab.present(nav, animated: true, completion: nil)
                }
            }
        }
    }
}
