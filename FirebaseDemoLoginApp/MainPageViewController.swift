//
//  MainPageViewController.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/4/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class MainPageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
    
    @IBAction func LogoutAction(_ sender: Any)
    {
        HandleLogout()
    }
    
    func HandleLogout()
    {
        do
        {
            try Auth.auth().signOut()
        }catch let logouterror{
            print(logouterror.localizedDescription)
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }

}
