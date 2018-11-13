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
    
   
    @IBOutlet weak var NavItemView: UIView!
    @IBOutlet weak var NavItemLabelView: UILabel!
    @IBOutlet weak var NavitemImageView: UIImageView!
    @IBOutlet weak var NavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GetSingleUserData()
        AddTapGesture()
       
    }
    
    func AddTapGesture()
    {
        let tap = UITapGestureRecognizer(target: self, action: #selector(NavigationItemTouch))
        NavItemView.isUserInteractionEnabled = true
        self.NavItemView.addGestureRecognizer(tap)
    }
    
    @objc func NavigationItemTouch()
    {
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController")
        self.navigationController?.pushViewController(nav!, animated: true)
    }
    
    @IBAction func LogoutAction(_ sender: Any)
    {
        HandleLogout()
    }
    
    func HandleLogout()
    {
        do
        {
            UserDefaults.standard.set(false, forKey: "UserLogin")
            try Auth.auth().signOut()
        }catch let logouterror{
            print(logouterror.localizedDescription)
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func GetSingleUserData()
    {
        NavitemImageView.layer.cornerRadius = 10
        NavitemImageView.clipsToBounds = true
        NavItemLabelView.adjustsFontSizeToFitWidth = true
        NavItemView.backgroundColor = UIColor.clear
        
        DispatchQueue.main.async {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {(snapshot) in
                
                if let dictionary = snapshot.value as? [String:AnyObject]
                {
                    self.NavItemLabelView.text = dictionary["name"] as? String
                    self.NavitemImageView.LoadImageUsingCache(Urlstring: dictionary["ProfileImageURL"] as! String)
                }
                
            }, withCancel: nil)
        }
    }
    @IBAction func AllUsers(_ sender: Any)
    {
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "AllUsersViewController")
        self.navigationController?.pushViewController(nav!, animated: true)
    }
}
