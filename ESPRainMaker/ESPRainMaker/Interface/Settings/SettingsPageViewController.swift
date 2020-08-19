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
//  SettingsPageViewController.swift
//  ESPRainMaker
//

import Foundation
import JWTDecode
import UIKit

class SettingsPageViewController: UIViewController {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var changePasswordView: UIView!
    @IBOutlet var appVersionLabel: UILabel!
    var username = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        if User.shared.userInfo.loggedInWith == .other {
            changePasswordView.isHidden = true
        }

        emailLabel.text = User.shared.userInfo.email
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
        appVersionLabel.text = "App Version - v" + Constants.appVersion + " (\(GIT_SHA_VERSION))"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
            for item in subview.subviews {
                item.setNeedsDisplay()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    @IBAction func signOut(_: Any) {
        User.shared.currentUser()?.signOut()
        UserDefaults.standard.removeObject(forKey: Constants.userInfoKey)
        UserDefaults.standard.removeObject(forKey: Constants.refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.accessTokenKey)
        User.shared.accessToken = nil
        User.shared.userInfo = UserInfo(username: "", email: "", userID: "", loggedInWith: .cognito)
        User.shared.associatedNodeList = nil
        navigationController?.popViewController(animated: true)
        refresh()
    }

    func refresh() {
        User.shared.currentUser()?.getDetails().continueOnSuccessWith { (_) -> AnyObject? in
            DispatchQueue.main.async {}
            return nil
        }
    }

    @IBAction func openPrivacy(_: Any) {
        if Utility.isConnected(view: view) {
            showDocumentVC(url: "https://rainmaker.espressif.com/docs/privacy-policy.html")
        }
    }

    @IBAction func openTC(_: Any) {
        if Utility.isConnected(view: view) {
            showDocumentVC(url: "https://rainmaker.espressif.com/docs/terms-of-use.html")
        }
    }

    @IBAction func openDocumentation(_: Any) {
        showDocumentVC(url: "https://rainmaker.espressif.com")
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }

    func imageWith(name: String?) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let nameLabel = UILabel(frame: frame)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = .white
        nameLabel.textColor = .lightGray
        nameLabel.font = UIFont.boldSystemFont(ofSize: 40)
        nameLabel.text = name
        UIGraphicsBeginImageContext(frame.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "changePasswordSegue" {
            let changePasswordVC = segue.destination as! ChangePasswordViewController
            changePasswordVC.username = username
        }
    }
}
