//
//  Controller.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 16.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import Firebase

class Controller: UITabBarController {

    var firebaseUser = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myGroup = DispatchGroup()
        myGroup.enter()
        
        let allVC = self.viewControllers
        let SearchVC = allVC![0] as! SearchVC
        let MessageVC = allVC![1] as! MessagesVC
        let MyAccountVC = allVC![2] as! MyAccountVC
        let SettingsVC = allVC![3] as! SettingsVC
        
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            MyAccountVC.currentUser = self.firebaseUser
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
