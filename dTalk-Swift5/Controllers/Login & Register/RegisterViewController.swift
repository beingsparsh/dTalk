//
//  RegisterViewController.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 12/03/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    
    private let imageView : UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray.cgColor
        imageView.contentMode = .scaleAspectFit
        return imageView
        
    }()
    
    // Make it into Right-View (Internal Text, search on stack overflow) - Email Field and Password Field
    
    private let firstNameField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue  // When User press the enter, he is switched to the password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGreen.cgColor
        field.placeholder = "First Name"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField : UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue  // When User press the enter, he is switched to the password field
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGreen.cgColor
        field.placeholder = "Last Name"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
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
    
    private let registerButton : UIButton = {
        let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        view.backgroundColor = .systemBackground // Background color of login screen(may add animation and logo at this page
        /*
         navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
         style: .done,
         target: self, action: #selector(didTapRegister))
         */
        registerButton.addTarget(self,
                                 action: #selector(registerButtonTapped),
                                 for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        
        // Add Subview
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePicture))
        //  gesture.numberOfTouchesRequired =
        
        imageView.addGestureRecognizer(gesture)
        
    }
    
    @objc private func didTapChangeProfilePicture(){
        // print("Change Pic Called")
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom + 10,
                                      width: scrollView.width - 60,
                                      height: 52)
        lastNameField.frame = CGRect(x: 30,
                                     y: firstNameField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        registerButton.frame = CGRect(x: 30,
                                      y: passwordField.bottom + 10,
                                      width: scrollView.width - 60,
                                      height: 52)
    }
    
    // Password is 8-Character Long !!
    
    @objc private func registerButtonTapped(){
        
        emailField.resignFirstResponder() // Remove Keyboard From The Screen
        passwordField.resignFirstResponder()
        
        guard let firstName = firstNameField.text, let lastName = lastNameField.text, let email = emailField.text,  let password = passwordField.text, !firstName.isEmpty, !lastName.isEmpty,
              !email.isEmpty, !password.isEmpty, password.count >= 8 else {
            return alertUserLoginError(message: "")
        }
        
        spinner.show(in: view)
        
        // Firebase SignUp (Register)
        
        /// To check weather email exist in the database or not (using userExist library from resources)
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exist in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exist else {
                // User Already Exist
                
                DispatchQueue.main.async {
                    strongSelf.alertUserLoginError(message: "Looks like a user account for this email already exist")
                }
                return
            }
            
            /// If there is no dublicate user, here the firebase auth resgister a new user
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: {authResult, error in
                guard authResult != nil , error == nil else {
                    strongSelf.alertUserLoginError(message: "Looks like a user account for this email already exist")
                    print("Error Creating User")
                    return
                }
                
                let chatUser = chatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAddress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success{
                        // Upload Image
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
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
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil) //Automatic Switch to Chat View (strong self is use to avoid memory leak)
            })
        })
    }
    
    func alertUserLoginError (message : String) {
        
        let alert = UIAlertController(title: "Sign Up Error",
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
    
    /*
     @objc private func didTapRegister(){
     let vc = RegisterViewController()
     vc.title = "Create Account"
     navigationController?.pushViewController(vc, animated: true)   // Animation can be edited here
     }
     */
}


extension RegisterViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        return true
    }
}



extension RegisterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How you you like to select a profile picture",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentCamera()
                                                
                                            }))
        
        actionSheet.addAction(UIAlertAction(title: "Chose Photo",
                                            style: .default,
                                            handler: { [weak self]_ in
                                                
                                                self?.presentPhotoPicker()
                                                
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
