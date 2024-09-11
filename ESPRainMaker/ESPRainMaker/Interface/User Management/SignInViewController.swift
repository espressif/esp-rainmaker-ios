//
// Copyright 2014-2018 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License").
// You may not use this file except in compliance with the
// License. A copy of the License is located at
//
//     http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, express or implied. See the License
// for the specific language governing permissions and
// limitations under the License.
//

import Alamofire
import AuthenticationServices
import Foundation
import JWTDecode
import SafariServices
import WidgetKit

#if ESPRainMakerMatter
protocol RainmakerControllerFlowDelegate: AnyObject {
    func cloudLoginConcluded(cloudResponse: ESPSessionResponse?, groupId: String, matterNodeId: String)
    func controllerFlowCancelled()
}
#endif

protocol AgreementViewDisplayDelegate: AnyObject {
    func flowCancelled()
    func passwordResetSuccess()
}

class SignInViewController: UIViewController, ESPNoRefreshTokenLogic, UITextViewDelegate {
    
    @IBOutlet weak var controllerSigninButton: PrimaryButton!
    @IBOutlet weak var closeButton: PrimaryButton!
    @IBOutlet var checkBox: UIButton!
    @IBOutlet var signInTopSpace: NSLayoutConstraint!
    @IBOutlet var signUpTopView: NSLayoutConstraint!
    @IBOutlet var signInButton: PrimaryButton!
    @IBOutlet var username: UITextField!
    @IBOutlet var signUpButton: PrimaryButton!
    @IBOutlet var password: UITextField!
    @IBOutlet var topView: UIView!
    @IBOutlet var signUpView: UIView!
    @IBOutlet var signInView: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var githubLoginButton: UIButton!
    @IBOutlet var googleLoginButton: UIButton!
    @IBOutlet var appleLoginButton: UIButton!
    @IBOutlet var appVersionLabel: UILabel!
    @IBOutlet var signupTextView: UITextView!
    @IBOutlet weak var agreementTextView: UITextView!
    @IBOutlet weak var agreementView: UIView!
    @IBOutlet weak var agreementBox: UIButton!
    var sentTo: String?

    @IBOutlet var registerPassword: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet var email: UITextField!
    @IBOutlet weak var brandLogo: UIImageView!

    //MARK: China specific UI:
    
    @IBOutlet weak var forgotPasswordButton: SecondaryButton!
    @IBOutlet var githubLogo: UIImageView!
    @IBOutlet var googleLogo: UIImageView!
    @IBOutlet var appleLogo: UIImageView!
    @IBOutlet weak var chinaAppleLogo: UIImageView!
    @IBOutlet weak var chinaAppleSigninButton: UIButton!
    @IBOutlet weak var chinaWeChatLogo: UIImageView!
    @IBOutlet weak var chinaWeChatLoginButton: UIButton!
    @IBOutlet var useEmailLabel: UILabel!
    @IBOutlet weak var registrationLabel: UILabel!
    @IBOutlet weak var appVersionBottomConstraint: NSLayoutConstraint!
    
    var usernameText: String?
    var session: SFAuthenticationSession!
    var checked = false
    var agreementChecked = false
    
    // String constants
    let privacyLink = "privacy"
    let termsOfUseLink = "termsOfUse"
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var showAgreementView: Bool = true
    
    var service: ESPLoginService?
    
    #if ESPRainMakerMatter
    var isRainmakerControllerFlow = false
    var groupId: String = ""
    var matterNodeId: String = ""
    weak var rainmakerControllerDelegate: RainmakerControllerFlowDelegate?
    #endif

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #if ESPRainMakerMatter
        setCloseButtonUI()
        #else
        setSigninButtonUI()
        #endif
        segmentControl.selectedSegmentIndex = 0
        changeSegment()
        password.text = ""
        username.text = ""
        registerPassword.text = ""
        confirmPassword.text = ""
        email.text = ""
        checked = false
        checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)

        githubLoginButton.layer.backgroundColor = UIColor.white.cgColor
        githubLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        githubLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        githubLoginButton.layer.shadowRadius = 0.5
        githubLoginButton.layer.shadowOpacity = 0.5
        githubLoginButton.layer.masksToBounds = false

        googleLoginButton.layer.backgroundColor = UIColor.white.cgColor
        googleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        googleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        googleLoginButton.layer.shadowRadius = 0.5
        googleLoginButton.layer.shadowOpacity = 0.5
        googleLoginButton.layer.masksToBounds = false

        appleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        appleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        appleLoginButton.layer.shadowRadius = 0.5
        appleLoginButton.layer.shadowOpacity = 0.5
        appleLoginButton.layer.masksToBounds = false

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        var currentBGColor: UIColor!
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            currentBGColor = UIColor(hexString: "#8265E3")
        }
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .normal)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .selected)
        segmentControl.changeUnderlineColor(color: currentBGColor)
        #if ESPRainMakerMatter
        if self.isRainmakerControllerFlow {
            self.showAgreementScreen(showAgreementView: false)
        } else {
            self.showAgreementScreen(showAgreementView: true)
        }
        #else
        self.showAgreementScreen(showAgreementView: true)
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if ESPRainMakerMatter
        setCloseButtonUI()
        #else
        setSigninButtonUI()
        #endif
        if User.shared.automaticLogin {
            User.shared.automaticLogin = false
            password.text = User.shared.password
            username.text = User.shared.username
            signIn(username: User.shared.username, password: User.shared.password)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        // Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        } else {
            // Fallback on earlier versions
        }
        segmentControl.addUnderlineForSelectedSegment()
        appVersionLabel.text = "App Version - v" + Constants.appVersion + " (\(GIT_SHA_VERSION))"
        agreementTextView.delegate = self
        signupTextView.delegate = self

        let regularText = NSMutableAttributedString(string: "By proceeding, I confirm that I am 18+ years of age and I have read and agree to the ", attributes: [ NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
        // Sets attributes for clickable text in the UITextView string.
        let attributes:[NSAttributedString.Key : Any] = [NSAttributedString.Key.underlineStyle: 1, NSAttributedString.Key.underlineColor: UIColor(hexString: "#8265E3"), NSAttributedString.Key.foregroundColor: UIColor(hexString: "#8265E3"), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]
        let privacyText = NSMutableAttributedString(string: "Privacy Policy")
        privacyText.addAttributes(attributes, range: NSMakeRange(0, privacyText.length))
        privacyText.addAttributes([NSAttributedString.Key.link: privacyLink], range: NSMakeRange(0, privacyText.length))
        regularText.append(privacyText)
        regularText.append(NSMutableAttributedString(string: " and ", attributes: [ NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]))
        let termsOfUseText = NSMutableAttributedString(string: "Terms of Use.")
        termsOfUseText.addAttributes(attributes, range: NSMakeRange(0, termsOfUseText.length))
        termsOfUseText.addAttributes([NSAttributedString.Key.link: termsOfUseLink], range: NSMakeRange(0, termsOfUseText.length))
        regularText.append(termsOfUseText)
    
        agreementTextView.attributedText = regularText
        agreementTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: "#8265E3")]
        regularText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, regularText.length))
        signupTextView.attributedText = regularText
        signupTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: "#8265E3")]
        if Configuration.shared.appConfiguration.supportConfigOverride {
            self.configureBrandLogo()
        } else {
            self.resetConfig()
        }
        self.configureLocaleUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
            signUpConfirmationViewController.signupDelegate = self
        }  else if let forgotPasswordViewController = segue.destination as? ForgotPasswordViewController {
            forgotPasswordViewController.forgotPasswordDelegate = self
        }
    }
    
    /// Show agreement screen
    /// - Parameter showAgreementView: show/hide
    func showAgreementScreen(showAgreementView: Bool) {
        self.agreementView.isHidden = !showAgreementView
        self.showAgreementView = showAgreementView
    }
    
    // UITextViewDelegate method to handle callbacks for clickable text.
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == privacyLink {
            openPrivacy(self)
            return false
        } else if URL.absoluteString == termsOfUseLink {
            openTC(self)
            return false
        }
        return true
    }
    
    @IBAction func closeSigninVC(_ sender: Any) {
        #if ESPRainMakerMatter
        User.shared.updateDeviceList = true
        self.rainmakerControllerDelegate?.controllerFlowCancelled()
        self.dismiss(animated: true, completion: nil)
        #endif
    }
    
    func resetConfig() {
        UserDefaults.standard.removeObject(forKey: Constants.overriddenBaseURLKey)
        Configuration.shared.awsConfiguration.resetBaseURLFromConfig()
        self.resetParamURL()
    }
        
    func resetParamURL() {
        ESPServerTrustParams.shared.setParams(fileName: "amazonRootCA",
                                              baseURLDomain: Configuration.shared.awsConfiguration.baseURL.getDomain(),
                                              authURLDomain: Configuration.shared.awsConfiguration.authURL.getDomain(),
                                              claimURLDomain: Configuration.shared.awsConfiguration.claimURL.getDomain())
        ESPURLParams.shared.setURLs(baseURL: Configuration.shared.getAWSBaseURL(),
                                    authURL: Configuration.shared.awsConfiguration.authURL,
                                    redirectURL: Configuration.shared.awsConfiguration.redirectURL,
                                    appClientID: Configuration.shared.awsConfiguration.appClientId,
                                    userPool: Configuration.shared.appConfiguration.userPool)
    }
    
    func configureBrandLogo() {
        self.brandLogo.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(logoTapped))
        tap.numberOfTapsRequired = 5
        self.brandLogo.addGestureRecognizer(tap)
    }
        
    @objc func logoTapped() {
        let alert = UIAlertController(title: "Config", message: "Enter new base URL", preferredStyle: .alert)
        alert.addTextField { textField in
            if let text = UserDefaults.standard.value(forKey: Constants.overriddenBaseURLKey) as? String {
                textField.text = text
            } else {
                textField.text = Configuration.shared.awsConfiguration.baseURL
            }
        }
        alert.addAction(UIAlertAction(title: "Update value", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let text = textField!.text
            if let text = text, text.count > 0 {
                UserDefaults.standard.setValue(text, forKey: Constants.overriddenBaseURLKey)
                Configuration.shared.awsConfiguration.baseURL = text
                self.resetParamURL()
            }
        }))
        if let text = UserDefaults.standard.value(forKey: Constants.overriddenBaseURLKey) as? String, text.count > 0 {
            alert.addAction(UIAlertAction(title: "Reset to defaults", style: .default) { _ in
                self.resetConfig()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func segmentChange(sender _: UISegmentedControl) {
        changeSegment()
    }

    @IBAction func clickOnAgree(_: Any) {
        checked = !checked
        if checked {
            checkBox.setImage(UIImage(named: "checkbox_checked"), for: .normal)
        } else {
            checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)
        }
    }

    func changeSegment() {
        if segmentControl.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = true
                self.signUpView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = false
                self.signUpView.isHidden = true
            }
        }
        segmentControl.changeUnderlinePosition()
    }

    @IBAction func loginWithGoogle(_: Any) {
        loginWith(idProvider: "Google")
    }

    @IBAction func loginWithApple(_: Any) {
        loginWith(idProvider: "SignInWithApple")
    }

    @IBAction func loginWithGithub(_: Any) {
        loginWith(idProvider: "GitHub")
    }

    func loginWith(idProvider: String) {
        
        let service = ESPIdProviderLoginService(presenter: self)
        service.loaderDelegate = self
        service.loginWith(idProvider: idProvider)
    }
    
    /// This API call is to retrieve WeChat Tokens
    /// - Parameter authCode: WeChat auth code
    func requestWeChatTokens(authCode: String) {
        DispatchQueue.main.async {
            Utility.showLoader(message: "", view: self.view)
        }
        let url = Configuration.shared.awsConfiguration.authURL + "/token"
        let parameters: [String: Any] = [ESPAPIKeys.grantType: ESPAPIKeys.authorizationCode,
                          ESPAPIKeys.clientId: Configuration.shared.awsConfiguration.appClientId!,
                          ESPAPIKeys.code: authCode,
                          ESPAPIKeys.isWeChatToken: true,
                          ESPAPIKeys.redirctURI: Configuration.shared.awsConfiguration.redirectURL]
        let headers: HTTPHeaders = [Constants.contentType: Constants.applicationFormURLEncoded]
        NetworkManager.shared.genericRequest(url: url,
                                             method: .post,
                                             parameters: parameters,
                                             encoding: URLEncoding.default,
                                             headers: headers) { response in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            if let json = response, let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                let decoder = JSONDecoder()
                if let requestToken = try? decoder.decode(RequestToken.self, from: jsonData) {
                    self.loginSuccess(requestToken: requestToken)
                }
            }
        }
    }

    func getViewController() -> UIViewController {
        return self
    }

    @IBAction func controllerSignInPressed(_: AnyObject) {
        self.signIn()
    }
    
    @IBAction func signInPressed(_: AnyObject) {
        self.signIn()
    }
    
    /// Sign in pressed
    func signIn() {
        dismissKeyboard()
        signInButton.isEnabled = false
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            guard let usernameValue = username.text, !usernameValue.isEmpty, let password = password.text, !password.isEmpty else {
                let alertController = UIAlertController(title: "Missing information",
                                                        message: "Please enter a valid user name and password",
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                present(alertController, animated: true, completion: nil)
                signInButton.isEnabled = true
                return
            }
            signIn(username: usernameValue, password: password)
        }
    }

    func signIn(username: String, password: String) {
        Utility.showLoader(message: "Signing in", view: view)
        User.shared.username = username
        #if ESPRainMakerMatter
        if self.isRainmakerControllerFlow {
            self.service = ESPLoginService(isRainmakerControllerFlow: true, presenter: self)
            self.service?.loginUser(name: username, password: password)
            return
        }
        #endif
        self.service = ESPLoginService(presenter: self)
        self.service?.loginUser(name: username, password: password)
    }

    func showAlert() {
        let alertController = UIAlertController(title: "Failure",
                                                message: "Failed to login. Please try again.",
                                                preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func signUp(_ sender: AnyObject) {
        dismissKeyboard()
        if ESPNetworkMonitor.shared.isConnectedToNetwork {
            guard let userNameValue = email.text, !userNameValue.isEmpty,
                  let passwordValue = registerPassword.text, !passwordValue.isEmpty
            else {
                let alertController = UIAlertController(title: "Missing Required Fields",
                                                        message: "Username / Password are required for registration.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }

            if let confirmPasswordValue = confirmPassword.text, confirmPasswordValue != passwordValue {
                let alertController = UIAlertController(title: "Mismatch",
                                                        message: "Re-entered password do not match.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }

            if !checked {
                let alertController = UIAlertController(title: "Error!!",
                                                        message: "To proceed, please agree to privacy policy and terms of use.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            signUpButton.isEnabled = false
            Utility.showLoader(message: "", view: view)

            // sign up the user
            let service = ESPCreateUserService(presenter: self)
            service.createNewUser(name: userNameValue, password: passwordValue)
        }
    }

    @objc func keyboardNotification(notification _: NSNotification) {}

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = -100.0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = -50.0
            })
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = 0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = 0
            })
        }
    }

    @IBAction func openPrivacy(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.privacyPolicyURL)
    }

    @IBAction func openDocumentation(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.documentationURL)
    }

    @IBAction func openTC(_: Any) {
        showDocumentVC(url: Configuration.shared.externalLinks.termsOfUseURL)
    }

    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }
    
    func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        User.shared.updateDeviceList = true
    }

    func goToConfirmUserScreen() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let confirmUserVC = storyboard.instantiateViewController(withIdentifier: "confirmSignUpVC") as! ConfirmSignUpViewController
        confirmUserVC.confirmExistingUser = true
        confirmUserVC.sentTo = username.text ?? ""
        navigationController?.pushViewController(confirmUserVC, animated: true)
    }

    func resendConfirmationCode() {
        
        let service = ESPCreateUserService(presenter: self)
        service.createNewUser(name: username.text ?? "", password: password.text ?? "")
    }
    
    // MARK: Landing View
    
    @IBAction func agreementBoxClicked(_ sender: Any) {
        agreementChecked = !agreementChecked
        if agreementChecked {
            agreementBox.setImage(UIImage(named: "checkbox_checked"), for: .normal)
        } else {
            agreementBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)
        }
    }
    
    @IBAction func proceedClicked(_ sender: Any) {
        if !agreementChecked {
            let alertController = UIAlertController(title: "Error!!",
                                                    message: "To proceed, please agree to privacy policy and terms of use.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        } else {
            UIView.transition(with: agreementView, duration: 1.0, options: .transitionFlipFromRight) {
                self.agreementView.isHidden = true
            }
        }
    }

    #if ESPRainMakerMatter
    /// Set rainmaker properties
    /// - Parameters:
    ///   - isRainmakerControllerFlow: is rainmaker controller flow
    ///   - groupId: group id
    ///   - matterNodeId: matter node id
    ///   - rainmakerControllerDelegate: rainmaker controller delegate
    func setRainmakerControllerProperties(isRainmakerControllerFlow: Bool,
                                      groupId: String,
                                      matterNodeId: String,
                                      rainmakerControllerDelegate: RainmakerControllerFlowDelegate?) {
        self.isRainmakerControllerFlow = isRainmakerControllerFlow
        self.groupId = groupId
        self.matterNodeId = matterNodeId
        self.rainmakerControllerDelegate = rainmakerControllerDelegate
    }
    
    /// Set close button UI
    func setCloseButtonUI() {
        self.closeButton.isHidden = !self.isRainmakerControllerFlow
        self.controllerSigninButton.isHidden = !self.isRainmakerControllerFlow
        self.signInButton.isHidden = self.isRainmakerControllerFlow
        self.segmentControl.isHidden = self.isRainmakerControllerFlow
    }
    #endif
    
    /// Set sign in button UI
    func setSigninButtonUI() {
        self.closeButton.isHidden = true
        self.controllerSigninButton.isHidden = true
        self.signInButton.isHidden = false
    }
    
    /// Reload timelines for widget
    func refreshWidgets() {
        if #available(iOS 14.0, *) {
            if #available(iOS 16.0, *) {
                WidgetCenter.shared.invalidateConfigurationRecommendations()
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    //MARK: China specific actions
    func configureLocaleUI() {
        DispatchQueue.main.async {
            self.setUniversalUI(isLocaleChina: ESPLocaleManager.shared.isLocaleChina)
            self.setChinaSpecificButtons(isLocaleChina: ESPLocaleManager.shared.isLocaleChina)
        }
    }
    
    @IBAction func chinaLoginToApple(_ sender: Any) {
        loginWith(idProvider: "SignInWithApple")
    }
    
    @IBAction func chinaLoginToWeChhat(_ sender: Any) {
        if WXApi.isWXAppInstalled() {
            let req = SendAuthReq()
            req.scope = Configuration.shared.weChatServiceConfiguration.scope
            req.state = WeChatServiceConfiguration.state
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                WXApi.sendAuthReq(req, viewController: self, delegate: appDelegate) { result in
                    if !result {
                        self.showErrorAlert(title: "Failure", message: "Could not launch Weixin login.", buttonTitle: "OK") {}
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.showWeChatInstallOptions()
            }
        }
    }
    
    func showWeChatInstallOptions() {
        let title = "App Required"
        let message = "This feature requires WeChat to be installed on your device. Please install the app from the App Store to continue."
        let weChatAppStoreURL = "https://apps.apple.com/us/app/wechat/id414478124"
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let installWeChatOption = UIAlertAction(title: "Install", style: .default) { _ in
            if let installWeChatURL = URL(string: weChatAppStoreURL), UIApplication.shared.canOpenURL(installWeChatURL) {
                UIApplication.shared.open(installWeChatURL, options: [:], completionHandler: nil)
            } else {
                DispatchQueue.main.async {
                    Utility.showToastMessage(view: self.view, message: "Cannot open App Store. Please install WeChat application on your device.")
                }
            }
        }
        let cancelOption = UIAlertAction(title: "Cancel", style: .default)
        alertController.addAction(cancelOption)
        alertController.addAction(installWeChatOption)
        self.present(alertController, animated: false)
    }
    
    
    /// Set UI for non China locale
    /// - Parameter isLocaleChina: is locale China
    func setUniversalUI(isLocaleChina: Bool) {
        self.githubLogo.isHidden = isLocaleChina
        self.appleLogo.isHidden = isLocaleChina
        self.googleLogo.isHidden = isLocaleChina
        self.username.isHidden = isLocaleChina
        self.password.isHidden = isLocaleChina
        self.githubLoginButton.isHidden = isLocaleChina
        self.googleLoginButton.isHidden = isLocaleChina
        self.appleLoginButton.isHidden = isLocaleChina
        self.useEmailLabel.isHidden = isLocaleChina
        self.forgotPasswordButton.isHidden = isLocaleChina
        self.signInButton.alpha = isLocaleChina ? 0.0 : 1.0
        self.signInButton.isUserInteractionEnabled = !isLocaleChina
        self.segmentControl.alpha = isLocaleChina ? 0.0 : 1.0
        self.segmentControl.isUserInteractionEnabled = !isLocaleChina
        self.registrationLabel.text = isLocaleChina ? AppConstants.shared.icpRegistrationId : ""
    }
    
    /// Set China specific UI
    /// - Parameter isLocaleChina: is locale China
    func setChinaSpecificButtons(isLocaleChina: Bool) {
        self.chinaAppleLogo.isHidden = !isLocaleChina
        self.chinaAppleSigninButton.isHidden = !isLocaleChina
        self.chinaAppleSigninButton.isUserInteractionEnabled = isLocaleChina
        if ESPLocaleManager.shared.isLocaleChinaWithWeChatConfigured {
            self.chinaWeChatLogo.isHidden = !isLocaleChina
            self.chinaWeChatLoginButton.isHidden = !isLocaleChina
            self.chinaWeChatLoginButton.isUserInteractionEnabled = isLocaleChina
        } else {
            self.chinaWeChatLogo.isHidden = true
            self.chinaWeChatLoginButton.isHidden = true
            self.chinaWeChatLoginButton.isUserInteractionEnabled = false
        }
    }
}



extension SignInViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.fullScreen
    }
}

extension SignInViewController: ASWebAuthenticationPresentationContextProviding {
    
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case username:
            password.becomeFirstResponder()
        case password:
            password.resignFirstResponder()
            signInPressed(textField)
        case email:
            registerPassword.becomeFirstResponder()
        case registerPassword:
            confirmPassword.becomeFirstResponder()
        case confirmPassword:
            confirmPassword.resignFirstResponder()
        default:
            return true
        }
        return true
    }
}

extension SignInViewController: ESPLoginPresentationLogic {
    
    func rainmakerControllerLoginCompleted(data: Data?) {
        #if ESPRainMakerMatter
        Utility.hideLoader(view: self.view)
        let decoder = JSONDecoder()
        if let data = data, let cloudResponse = try? decoder.decode(ESPSessionResponse.self, from: data) {
            if cloudResponse.isValid {
                self.rainmakerControllerDelegate?.cloudLoginConcluded(cloudResponse: cloudResponse, groupId: self.groupId, matterNodeId: self.matterNodeId)
                self.dismiss(animated: true)
            } else if let desc = cloudResponse.description {
                self.alertUser(title: ESPMatterConstants.failureTxt,
                               message: desc,
                               buttonTitle: ESPMatterConstants.okTxt) {
                    self.signInButton.isEnabled = true
                }
            }
        } else {
            self.rainmakerControllerDelegate?.cloudLoginConcluded(cloudResponse: nil, groupId: self.groupId, matterNodeId: self.matterNodeId)
            self.dismiss(animated: true)
        }
        #endif
    }

    func loginCompleted(withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.signInButton.isEnabled = true
            if error != nil {
                var title: String? = "Error"
                var message: String? = ""
                switch error {
                case .serverError(let serverError):
                    if (serverError as NSError).code == 33 {
                        self.resendConfirmationCode()
                        return
                    }
                    if let text = (serverError as NSError).userInfo["__type"] as? String {
                        title = text
                    }
                    if let text = (serverError as NSError).userInfo["message"] as? String {
                        message = text
                    }
                case .errorCode(let errorCode, let desc):
                    if errorCode == ESPErrorCodeDescription.emailNotVerifiedKey {
                        self.resendConfirmationCode()
                        return
                    }
                    message = desc
                default:
                    break
                }
                let alertController = UIAlertController(title: title,
                                                        message: message,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry",
                                                style: .default,
                                                handler: nil)
                alertController.addAction(retryAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                self.username.text = nil
                self.password.text = nil
                User.shared.updateUserInfo = true
                // Configure remote notification.
                self.appDelegate?.configureRemoteNotifications()
                self.refreshWidgets()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension SignInViewController: ESPCreateUserPresentationLogic {
    
    func verifyUser(withName name: String, andPassword password: String, withError error: ESPAPIError?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            self.signUpButton.isEnabled = true
            if error != nil {
                self.handleError(error: error, buttonTitle: "Retry")
            } else {
                User.shared.username = name
                User.shared.password = password
                self.sentTo = name
                self.performSegue(withIdentifier: "confirmSignUpSegue", sender: self.signUpButton)
            }
        }
    }
    
    func userVerified(withError error: ESPAPIError?) {}
}

extension SignInViewController: ESPIdProviderLoginPresenter {
    
    func loginFailed() {
        self.showAlert()
    }
    
    func loginSuccess(requestToken: RequestToken) {
        #if ESPRainMakerMatter
        if self.isRainmakerControllerFlow {
            var cloudResponse = ESPSessionResponse()
            cloudResponse.accessToken = requestToken.accessToken
            cloudResponse.idToken = requestToken.idToken
            cloudResponse.refreshToken = requestToken.refreshToken
            self.rainmakerControllerDelegate?.cloudLoginConcluded(cloudResponse: cloudResponse, groupId: self.groupId, matterNodeId: self.matterNodeId)
            self.dismiss(animated: true)
            return
        }
        #endif
        let umTokenWorker = ESPTokenWorker.shared
        if let refreshToken = requestToken.refreshToken {
            umTokenWorker.save(value: refreshToken, key: Constants.refreshTokenKey)
        }
        if let idToken = requestToken.idToken {
            umTokenWorker.save(value: idToken, key: Constants.idTokenKey)
            self.getUserInfo(token: idToken, provider: .other)
        }
        if let accessToken = requestToken.accessToken {
            User.shared.accessToken = accessToken
            umTokenWorker.save(value: accessToken, key: Constants.accessTokenKey)
            DispatchQueue.main.async {
                // Configure remote notification.
                self.appDelegate?.configureRemoteNotifications()
                self.dismiss(animated: true, completion: nil)
                self.refreshWidgets()
            }
        }
    }
}

extension SignInViewController: AgreementViewDisplayDelegate {
    
    func passwordResetSuccess() {
        showAgreementView = false
    }
    
    func flowCancelled() {
        showAgreementView = false
    }
}

extension SignInViewController: LoaderDelegate {
    
    func showLoader() {
        DispatchQueue.main.async {
            Utility.showLoader(message: "Signing in", view: self.view)
        }
    }
    
    func hideLoader() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
    }
}
