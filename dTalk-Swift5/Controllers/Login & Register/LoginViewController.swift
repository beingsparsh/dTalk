//
//  LoginViewController.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 12/03/21.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD
import MessageUI // Adding email support for customer support

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    //  private var provider = OAuthProvider(providerID: "github.com")
    
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    
    private let imageView : UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo3") // Please Check this feature
        imageView.contentMode = .scaleAspectFit
        return imageView
        
    }()
    
    // Make it into Right-View (Internal Text, search on stack overflow) - Email Field and Password Field
    
    private let emailField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue  // When User press the enter, he is switched to the password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGreen.cgColor
        field.placeholder = "E-Mail Address"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done // When User press the enter, he is logged in
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGreen.cgColor
        field.placeholder = "Password"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let FBloginButton : FBLoginButton = {
        let button =  FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    
    private let googleLogInButton = GIDSignInButton()
    
    //    ----------------------------------------------------------- 30 May, 2021 - 11:48 PM
    private let emailSupport : UIButton = {
        let button = UIButton()
        button.setTitle("Email Support", for: .normal)
        button.backgroundColor = .systemBackground
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Notification Observer creater to dismiss the loginView after login (For Google SignIn) - More reference in appdelegate.swift
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self]_ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        )
        
        GIDSignIn.sharedInstance()?.presentingViewController = self /// For Google SignIn (additional Steps)
        
        title = "Log In"
        view.backgroundColor = .systemBackground // Background color of login screen(may add animation and logo at this page
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        FBloginButton.delegate = self
        
        // Add Subview
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(FBloginButton)
        scrollView.addSubview(googleLogInButton)
        
        scrollView.addSubview(emailSupport)
        emailSupport.addTarget(self,
                               action: #selector(emailSupportTapped),
                               for: .touchUpInside)
        
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 30,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 20,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        FBloginButton.frame = CGRect(x: 30,
                                     y: loginButton.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        googleLogInButton.frame = CGRect(x: 30,
                                         y: FBloginButton.bottom + 20,
                                         width: scrollView.width - 60,
                                         height: 52)
        
        emailSupport.frame = CGRect(x: 30,
                                   y: googleLogInButton.bottom + 40,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    //----------------------------- 31 May 2021 - 12:25 AM
    
    @objc private func emailSupportTapped(){
        //self.view.backgroundColor = .systemYellow
        print("emailSupport Button Tapped")
        showMailComposer()
    }
    
    func showMailComposer() {
        
        spinner.show(in: view)
        
        print("spineer started")
        
        guard MFMailComposeViewController.canSendMail() else {
            print("Cant send mail through a simulator")
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            return
        }
        
        spinner.dismiss()
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["singhsparsh@ducic.ac.in"])
        composer.setSubject("Help")
        composer.setMessageBody("Hi, I need your help with ", isHTML: false)
        
        present(composer, animated: true)
    }
    
    // Password is 8-Character Long !!
    
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder() // Remove Keyboard From The Screen
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,  let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 8 else {
            return alertUserLoginError()
        }
        
        spinner.show(in: view)
        // Firebase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            // Auth() works in background threads, view needs to be on main thread
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            
            guard let result = authResult, error == nil else {
                print("Failed to log in user using email : \(email)")
                return
            }
            
            let user = result.user
            
            
            UserDefaults.standard.set(email, forKey: "email") // Saving Email for Normal Firebase Auth
            
            
            //-----------------------------------------------------------------------------------------------
            // 23/04/2021 - 4:28 PM - Edit by admin(Sparsh)
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result{
                case .success(let data):
                    guard let userData = data as? [String : Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    
                     UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                
                case.failure(let error):
                    print("failed to fetch name from the database with error : \(error)")
                          
                }
            })

           
            
            //-----------------------------------------------------------------------------------------------
            print("Logged in user : \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil) //Automatic Switch to Chat View (strong self is use to avoid memory leak)
        })
        
    }
    
    func alertUserLoginError () {
        
        let alert = UIAlertController(title: "Error 101",
                                      message: "You Email address/password seems to be missing",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)   // Animation can be edited here
    }
    
}



extension LoginViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}


extension LoginViewController : LoginButtonDelegate{
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no opeartions
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User Failed to login with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completionHandler: { _, result, error in
            guard let result = result as? [String : Any],
                  error == nil else {
                print("failed to make facebook graph request")
                return
            }
            print("\(result)")
            
            //            return
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String : Any],
                  let data = picture["data"] as? [String:Any],
                  let pictureURL = data["url"] as? String else {
                print("Failed to get name and email from FB result")
                return
            }
            
            
            UserDefaults.standard.set(email, forKey: "email") // Saving Email From FB Login
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            let chatUser = chatAppUser(firstName: firstName,
                                       lastName: lastName,
                                       emailAddress: email)
            
            
            DatabaseManager.shared.userExists(with: email, completion: {exist in
                if !exist {
                    DatabaseManager.shared.insertUser(with: chatUser,completion: { success in
                        if success {
                            
                            guard let url = URL(string: pictureURL) else {
                                return
                            }
                            
                            print("downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _ , _ in
                                guard let data = data else{
                                    print("failed to get data from facebook")
                                    return
                                }
                                
                                print("got data from facebook, uploading !!")
                                //                             upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName,completion: {result in
                                    switch result {
                                    case .success(let downloadURL) :
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_URL")
                                        print(downloadURL)
                                    case .failure(let error) :
                                        print("Storage manager error : \(error)")
                                    }
                                    
                                })
                            }).resume()
                            
                            
                        }
                        
                    })
                }
            })
            
            // Credentials start auth()
            
            let credentials = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credentials, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil, error == nil  else {
                    if let error = error{
                        print("Facebook credentials login failed, MFA maybe needed - \(error)")
                    }
                    
                    return
                }
                
                print("Succesfully logged in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
            // Credentials Ending
        })
        
        
    }
    
    
}


//---------------------
extension LoginViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let _ = error {
            // Mail was not sent
            controller.dismiss(animated: true)
            return
        }
        
        switch result {
        case .cancelled :
            print("cancelled")
        case .saved:
            print("saved")
        case .sent:
            print("sent")
        case .failed:
            print("failed")
        }
        
        controller.dismiss(animated: true)
    }
}
