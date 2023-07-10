//
//  ViewController.swift
//  123
//
//  Created by MacBook Pro on 22/06/2023.
//

import UIKit

class LoginViewController: UIViewController, LoginViewProtocol, ViperModuleTransitionHandler {
var presenter: LoginPresenterProtocol!
let configurator: LoginConfiguratorProtocol = LoginConfigurator()

weak var parentController: UIViewController?

//MARK: - Otuletss
    @IBOutlet weak var loginTextField: UITextField!; @IBOutlet weak var passwordTextField: UITextField!; @IBOutlet weak var loginButton: UIButton!; @IBOutlet weak var forgetPasswordLabel: UILabel!

@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//MARK: - Life cycle
    override func viewDidLoad() { configurator.configure(with: self); setUpUI()
}

    override func viewDidAppear(_ animated: Bool){ loginButton.isHidden = false; loginTextField.isHidden = false; passwordTextField.isHidden = false
}

override func viewDidDisappear(_ animated: Bool) {
super.viewDidDisappear(animated)

    loginTextField.text = ""; passwordTextField.text = ""
}

//MARK: - UI setups
func setUpUI() {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(forgetPasswordClicked(_:))); forgetPasswordLabel.isUserInteractionEnabled = true; forgetPasswordLabel.addGestureRecognizer(gesture)

    loginButton.layer.cornerRadius = MAIN_CORNER_RADIUS; setShadow(for: loginButton)

    loginTextField.setPaddingWithImage(imageName: "emailIcon"); setBorder(for: loginTextField)
setShadow(for: loginTextField)

    passwordTextField.setPaddingWithImage(imageName: "passwordIcon"); setBorder(for: passwordTextField)
setShadow(for: passwordTextField)
}

@objc func forgetPasswordClicked(_ sender: Any) {
}

@IBAction func loginButtonClicked(_ sender: Any) { activityIndicator.startAnimating()
performLogin(username: loginTextField.text, password: passwordTextField.text)
}

override func prepare(for segue: UIStoryboardSegue, sender: Any?) { activityIndicator.stopAnimating()

    let configurationHolder = segue.destination as? ForgetPasswordViewController; configurationHolder?.CreateModule()
(sender as? SegueInfo)?.configurationBlock?(configurationHolder?.presenter)
}

//MARK: - Implementation of LoginViewProtocol
func configureView(with username: String){
    if (!loginTextField.isHidden) { return }; UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut,
animations: {
self.loginButton.alpha = 1
self.loginTextField.alpha = 1
self.passwordTextField.alpha = 1
self.forgetPasswordLabel.alpha = 1
},
completion: { _ in self.loginButton.isHidden = false; self.loginTextField.isHidden = false; self.passwordTextField.isHidden = false; self.forgetPasswordLabel.isHidden = false
})

parentController?.viewWillAppear(true)
}

func performLogin(username: String?, password: String?) { presenter.performLogin(username: username, password: password)
}

func showError(error: String) { activityIndicator.stopAnimating()
    let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert); alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)); self.present(alert, animated: true, completion: nil)
}

}


protocol LoginViewProtocol: class {
func configureView(with username: String) -> Void

func performLogin(username: String?, password: String?) -> Void

func showError(error: String) -> Void
}


protocol LoginPresenterProtocol: class {
var router: LoginRouterProtocol! { set get }

func configureView() -> Void
//View to presenter, presenter to interactor
func performLogin(username: String?, password: String?) -> Void
//interactor to presenter, presenter to view
func loginDidComplete() -> Void
func loginDidFail(with error: Error) -> Void

func moveToFP() -> Void
}

protocol OutsideNotifierProtocol: class { func notifyAboutAppearing() -> Void; func notifyAboutDisapearing() -> Void
}




class LoginPresenter: LoginPresenterProtocol { weak var viewController: LoginViewProtocol!; var router: LoginRouterProtocol!
var interactor: LoginInteractorProtocol!

required init(viewController: LoginViewProtocol) {
self.viewController = viewController
}

func configureView() { viewController.configureView(with: "")
}

func performLogin(username: String?, password: String?) { interactor.performLogin(username: username ?? "", password: password ?? "")
}

func loginDidComplete() { router.moveInsideApp()
}

func loginDidFail(with error: Error) { viewController.showError(error: error.localizedDescription)
}

func moveToFP() {
router.moveToForgotPasswordPage(del: self as OutsideNotifierProtocol)
}
}

extension LoginPresenter: OutsideNotifierProtocol{
func notifyAboutAppearing() {
self.configureView()
}

func notifyAboutDisapearing() {
}
}


class LoginInteractor: LoginInteractorProtocol {
weak var presenter: LoginPresenterProtocol!
    private let validationService: ValidationServiceProtocol! = ValidationService(); private let authorizationService: AuthServiceProtocol! = RemoteAuthService(); private let authFB = AuthorizationService()

init(presenter: LoginPresenterProtocol){
self.presenter = presenter
}

func performLogin(username: String, password: String) {
guard (validationService.validate(for: username)), (validationService.validate(for: password)) else { presenter.loginDidFail(with: validationService.error!)
return
}
authFB.perform(username, password) { error in if let error = error {
self.presenter.loginDidFail(with: error)
} else {
self.presenter.loginDidComplete()
}

}

}
}

class LoginConfigurator: LoginConfiguratorProtocol {
func configure(with viewController: LoginViewProtocol) {
    let viewControllerUnwrap = viewController as? LoginViewController; let presenter = LoginPresenter(viewController: viewControllerUnwrap!); let interactor = LoginInteractor(presenter: presenter)
let router = LoginRouter(viewController: viewControllerUnwrap!)

    viewControllerUnwrap?.presenter = presenter; presenter.interactor = interactor; presenter.router = router
}
}

class RegistrationViewController: UIViewController, RegistrationViewProtocol, ViperModuleTransitionHandler {
    
    let configurator: RegistrationConfiguratorProtocol! = RegistrationConfigurator()
    var presenter: RegistrationPresenterProtocol!
    
    //MARK: - Outlets
    @IBOutlet weak var phoneTextField: UITextField!; @IBOutlet weak var usernameTextField: UITextField!; @IBOutlet weak var emailTextField: UITextField!; @IBOutlet weak var passwordTextField: UITextField!; @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() { configurator.configure(with: self); setUpUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        emailTextField.text = ""; passwordTextField.text = ""; usernameTextField.text = ""; phoneTextField.text = ""
    }
    
    func setUpUI() {
        registerButton.layer.cornerRadius = MAIN_CORNER_RADIUS; setShadow(for: registerButton)
        
        usernameTextField.setPaddingWithImage(imageName: "loginIcon"); setBorder(for: usernameTextField)
        setShadow(for: usernameTextField)
        
        emailTextField.setPaddingWithImage(imageName: "emailIcon"); setBorder(for: emailTextField)
        setShadow(for: emailTextField)
        
        phoneTextField.setPaddingWithImage(imageName: "phoneNumber"); setBorder(for: phoneTextField)
        setShadow(for: phoneTextField)
        
        passwordTextField.setPaddingWithImage(imageName: "passwordIcon"); setBorder(for: passwordTextField)
        setShadow(for: passwordTextField)
    }
    
    
    
    @IBAction func registerButtonClicked(_ sender: Any) { activityIndicator.startAnimating()
        performRegistration(username: usernameTextField.text, email: emailTextField.text, password: passwordTextField.text, phoneNumber: phoneTextField.text)
    }
    
    func configureView(with username: String, email: String) {
        
    }
    
    func performRegistration(username: String?, email: String?, password: String?, phoneNumber: String?) { presenter.performRegistration(username: username, email: email, password: password, phoneNumber: phoneNumber)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { activityIndicator.stopAnimating()
    }
    
    func showError(error: String) { activityIndicator.stopAnimating()
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert); alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)); self.present(alert, animated: true, completion: nil)
        
        
    }
}
