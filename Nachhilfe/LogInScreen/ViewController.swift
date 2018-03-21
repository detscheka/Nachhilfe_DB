//
//  ViewController.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 07.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import FirebaseStorage
import FirebaseDatabase

class ViewController: UIViewController, FBSDKLoginButtonDelegate, GIDSignInUIDelegate, GIDSignInDelegate {

    @IBOutlet weak var LogInButton: UIButton!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var eMailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var ResetPasswordBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        
        LogInButton.layer.borderWidth = 1
        LogInButton.layer.borderColor = LogInButton.tintColor.cgColor
        LogInButton.layer.cornerRadius = 15
        
        RegisterButton.layer.borderWidth = 1
        RegisterButton.layer.borderColor = RegisterButton.tintColor.cgColor
        RegisterButton.layer.cornerRadius = 15
        
        ResetPasswordBtn.layer.borderWidth = 1
        ResetPasswordBtn.layer.borderColor = ResetPasswordBtn.tintColor.cgColor
        ResetPasswordBtn.layer.cornerRadius = 15
        
        LogInButton.tag = 1
        RegisterButton.tag = 2
        ResetPasswordBtn.tag = 3
        
    }
    
    fileprivate func setupButtons() {
        let logInFacebookButton = FBSDKLoginButton()
        view.addSubview(logInFacebookButton)
        logInFacebookButton.frame = CGRect(x: 16, y: self.passwordField.frame.midY + 50, width: view.frame.width - 30, height: 50)
        logInFacebookButton.delegate = self
        logInFacebookButton.readPermissions = ["email", "public_profile"]
        
        let googleButton = GIDSignInButton()
        googleButton.frame = CGRect(x: 16, y: logInFacebookButton.frame.midY + 50, width: view.frame.width - 30, height: 50)
        view.addSubview(googleButton)
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func LogInPressed(_ sender: UIButton) {
        
        switch sender.tag
        {
        case 1:
            if self.eMailField.text == "" || self.passwordField.text == "" {
                let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                Auth.auth().signIn(withEmail: self.eMailField.text!, password: self.passwordField.text!) {
                    (user, error) in
                    if error == nil {
                        print("You have successfully logged in with user: ", user!)
                        self.gotoMainAppVC(user: user!)
                    } else {
                        let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                        
                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(defaultAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        case 2:
            print("case2\n")
        case 3:
            print("case3\n")
        default:
            break
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        var fbUser: User!
        if error != nil {
            print(error.localizedDescription)
            return
        }
        
        guard let token = FBSDKAccessToken.current().tokenString else {return}
        let credentials = FacebookAuthProvider.credential(withAccessToken: token)
        Auth.auth().signIn(with: credentials) { (user, err) in
            if err != nil {
                print("Error occured while logging into Firebase with Facebook: ", err!)
                return
            }
            
            print("Successfully logged into Firebase with Facebook ", user!)
            fbUser = user
        }
        
        print("logged in!\n")
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, err) in
            if err != nil {
                print("Failed to start graph request: ", err!)
                return
            }
            
            // Write the data to Firebase
            let ref = Database.database().reference(fromURL: "https://nachhilfe-d92d2.firebaseio.com/")
            guard let uid = fbUser?.uid else {
                return
            }
            let usersReference = ref.child("users").child(uid)
            let resultDic = result as! NSDictionary
            
            let userName:NSString = resultDic.value(forKey: "name") as! NSString
            let userEmail:NSString = resultDic.value(forKey: "email") as! NSString
            let userID:NSString = resultDic.value(forKey: "id") as! NSString
            let values = ["name": userName, "email": userEmail, "facebookID": userID]
            
            usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
                if err != nil {
                    print(err!)
                    return
                }
                print("User info was saved to Firebase from Facebook!")
            })
            
            print(result!)
        }
        
        fbUser = Auth.auth().currentUser
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://nachhilfe-d92d2.appspot.com")
        let profilePicRef = storageRef.child(fbUser.uid+"/profile_pic.jpg")
        
        print(fbUser.uid)
        
        var imageFB : UIImage? = nil
        
        let myGroup = DispatchGroup()
        myGroup.enter()
        profilePicRef.getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
            if (error == nil) {
                DispatchQueue.main.async {
                    imageFB = UIImage(data: data!)
                }
            } else {
                print("There is no image to download yet. We have to upload a new image from Facebook.")
                print(error!)
            }
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            if imageFB == nil {
                print("There is no image uploaded in Firebase. We need to upload an image from Facebook.")
                
                let profilePic = FBSDKGraphRequest(graphPath: "me/picture", parameters: ["height": 300, "width": 300, "redirect": false], httpMethod: "GET")
                profilePic?.start(completionHandler: {(_ connection, result, error) -> Void in
                    
                    if error == nil {
                        if let dictionary = result as? [String: Any],
                            let data = dictionary["data"] as? [String:Any],
                            let urlPic = data["url"] as? String{
                            
                            if let imageData = NSData(contentsOf: NSURL(string: urlPic)!as URL){
                                
                                _ = profilePicRef.putData(imageData as Data, metadata: nil) {
                                    metadata, error in
                                    
                                    if (error == nil)
                                    {
                                        _ = metadata!.downloadURL
                                    }
                                    else
                                    {
                                        print("Error in downloading image")
                                        print(error!)
                                    }
                                }
                                
                                imageFB = UIImage(data: imageData as Data)!
                            }
                        }
                    }
                })
                self.gotoMainAppVC(user: fbUser)
                
            } else {
                print("There already is an image in Firebase.")
                self.gotoMainAppVC(user: fbUser)
            }
        }
        
    }
    
    func downloadImage(url: URL) -> UIImage {
        print("Download Started")
        var image = UIImage()
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                image = UIImage(data: data)!
            }
        }
        
        return image
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Logged out!\n")
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "segueShowResetPassword" {
            let resetController = segue.destination as! ResetPasswordVC
            resetController.LoginEmailString = self.eMailField.text!
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        var firebaseId: User!
        
        if let err = error {
            print("Failed to log in into Google: ", err)
            return
        }
        
        print("Successfully logged in into Google", user)
        
        guard let idToken =  user.authentication.idToken else {return}
        guard let accessToken = user.authentication.accessToken else {return}
        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credentials) { (user, error) in
            if let err = error {
                print("Failed to create a Firebase User with Google account: !", err)
                return
            }
            
            guard let uid = user?.uid else {return}
            print("Successfully logged into Firebase with Google: !", uid)
            firebaseId = (user)!
        }
        
        gotoMainAppVC(user: firebaseId)
    }
    
    func gotoMainAppVC(user: User)
    {
        if let tabViewController = storyboard?.instantiateViewController(withIdentifier: "TabBarControllerMain") as? Controller {
            present(tabViewController, animated: true, completion: nil)
            tabViewController.firebaseUser = user.uid
        } else {
            print("Error occured while switching to main tab bar screen!")
            return
        }
    }
    
}

