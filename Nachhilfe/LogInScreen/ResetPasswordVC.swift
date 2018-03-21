//
//  ResetPasswordVC.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 12.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import Firebase

class ResetPasswordVC: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    var LoginEmailString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.text = LoginEmailString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ResetButtonPressed(_ sender: Any) {
        Auth.auth().sendPasswordReset(withEmail: emailTextField.text!) { (err) in
            if err != nil {
                print("Error occured while resetting password: ", err!)
                
                let alertController = UIAlertController(title: "Please try again...", message: err?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            print("Successfully resetted the password!")
        }
    }
    
}
