//
//  AllUsersViewController.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/13/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit
import Firebase

class AllUsersViewController: UIViewController {
    
    var AllUsersArray : [UserModel] = []
    @IBOutlet weak var UserTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FetchUserData()
       
    }

    @IBAction func DoneAction(_ sender: UIBarButtonItem)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func FetchUserData()
    {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                
                let user = UserModel(dictionary: dictionary)
                user.uid = snapshot.key
            
//                user.name = dictionary["name"] as? String
//                user.email = dictionary["email"] as? String
                self.AllUsersArray.append(user)
                
                DispatchQueue.main.async {
                    self.UserTable.reloadData()
                }
            }
        }, withCancel: nil)
    }
}

extension AllUsersViewController : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AllUsersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserTableCell
        
        let Alluser = AllUsersArray[indexPath.row]
        cell.NameLabel.text = Alluser.name
        cell.EmailLabel.text = Alluser.email
        cell.ProfileImageView.LoadImageUsingCache(Urlstring: Alluser.ProfileImageURL!)
        cell.ProfileImageView.layer.cornerRadius = 20
        cell.ProfileImageView.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let Alluser = AllUsersArray[indexPath.row]
        
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        
        nav.user = Alluser
        
        self.navigationController?.pushViewController(nav, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
}

class UserTableCell : UITableViewCell
{
    @IBOutlet weak var EmailLabel: UILabel!
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var ProfileImageView: UIImageView!
}
