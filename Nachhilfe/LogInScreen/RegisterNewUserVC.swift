//
//  RegisterNewUserVC.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 07.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class RegisterNewUserVC: UIViewController {

    @IBOutlet weak var FirstNameTextField: UITextField!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var LastNameTextField: UITextField!
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        RegisterButton.layer.borderWidth = 1
        RegisterButton.layer.borderColor = RegisterButton.tintColor.cgColor
        RegisterButton.layer.cornerRadius = 15
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func RegisterButtonClicked(_ sender: UIButton) {
        if let email = EmailTextField.text, let password = PasswordTextField.text, let firstName = FirstNameTextField.text, let lastName = LastNameTextField.text {
            
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                
                if let firebaseError = error {
                    let alertController = UIAlertController(title: "Please try again...", message: firebaseError.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                
                let uid = (Auth.auth().currentUser?.uid)!
                let ref = Database.database().reference(withPath: "someStartPart/users").child(uid)
                ref.setValue(["uid": uid, "email": self.EmailTextField.text!, "FirstName": self.FirstNameTextField.text!, "LastName": self.LastNameTextField.text!,  "creationDate": String(describing: Date())])
                
                let alertController = UIAlertController(title: "Thank you!", message: "You can now log in using your E-Mail and Password.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
                    self.navigationController?.popToRootViewController(animated: true)
                }))

                self.present(alertController, animated: true, completion: nil)

            })
        }
    }


}
