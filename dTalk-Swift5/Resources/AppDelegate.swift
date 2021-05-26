//
//  AppDelegate.swift
//  dTalk-Swift5
//
//  Created by Sparsh Singh on 12/03/21.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error{
                print("Failed to signin with google : \(error)")
            }
            return
        }
        
        guard let user = user else {
            return
        }
        
        print("Sign In successful for the user : \(user)")
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName else {
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email") // Saving Email from Google SignIn
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        let chatUser = chatAppUser(firstName: firstName,
                                   lastName: lastName,
                                   emailAddress: email)
        
        DatabaseManager.shared.userExists(with: email, completion: { exist in
            if !exist {
                // Insert into databse
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success{
                        
                        if user.profile.hasImage{
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _ , _ in
                                guard let data = data else{
                                    print("failed to get data from facebook")
                                    return
                                }
                                // upload image
                                
                                
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
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Data of the google user is missing for auth()")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else {
                print("Failed to sign in with google credentials")
                return
            }
            
            // Successful
            
            print("Successfull signed in with google credentials")
            
            // Notification is used to dismiss the loginViewController / the navigation controller
            
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google User was disconnected")
    }
    
}

