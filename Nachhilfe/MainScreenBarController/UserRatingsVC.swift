//
//  UserRatingsVC.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 27.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit

class UserRatingsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "My Ratings"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    @IBAction func ButtonPressed(_ sender: UIBarButtonItem) {
        
        print("Done Button was pressed by user!")
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
}
