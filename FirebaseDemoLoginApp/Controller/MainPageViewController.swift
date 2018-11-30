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
    
    @IBOutlet weak var AllMessagetable: UITableView!
    @IBOutlet weak var NavItemView: UIView!
    @IBOutlet weak var NavItemLabelView: UILabel!
    @IBOutlet weak var NavItem: UINavigationItem!
    
    var AllUsersArray : [UserModel] = []
    var messages = [MessageModel]()
    var messagesDictionary = [String: MessageModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GetSingleUserData()
        //AddTapGesture()
        //FetchMessage()
        FetchUserData()
        messages.removeAll()
        messagesDictionary.removeAll()
        observeUserMessages()
        AllMessagetable.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        messages.removeAll()
        messagesDictionary.removeAll()
        observeUserMessages()
        AllMessagetable.reloadData()
    }

    func observeUserMessages() {
    
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesReference = Database.database().reference().child("Messages").child(messageId)
            
            messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
                if let dictionary = snapshot.value as? [String:AnyObject]
                {
                    let message = MessageModel(dictionary: dictionary)
                    
                    if let chatpartnetId = message.chatPartnerId() {
                        self.messagesDictionary[chatpartnetId] = message
                        
                        self.messages = Array(self.messagesDictionary.values)
                        self.messages.sort(by: { (message1, message2) -> Bool in
                            
                            let m1 = message1.date?.int32Value ?? 0
                            let m2 = message2.date?.int32Value ?? 0
                            
                            return m1 > m2
                        })
                    }
                    
                    DispatchQueue.main.async {
                        self.AllMessagetable.reloadData()
                    }
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    func FetchMessage()
    {
        
        let ref = Database.database().reference().child("Messages")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                let message = MessageModel(dictionary: dictionary)
                //self.AllTablemessage.append(AllMessage)
                
                if let toId = message.toid {
                    self.messagesDictionary[toId] = message
                    
                    self.messages = Array(self.messagesDictionary.values)
                    self.messages.sort(by: { (message1, message2) -> Bool in
                        
                        let m1 = message1.date?.int32Value ?? 0
                        let m2 = message2.date?.int32Value ?? 0
                        
                        return m1 > m2
                    })
                }
                
                DispatchQueue.main.async {
                    self.AllMessagetable.reloadData()
                }
            }
            
        }, withCancel: nil)
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
        NavItemLabelView.adjustsFontSizeToFitWidth = true
        NavItemView.backgroundColor = UIColor.clear
        
        DispatchQueue.main.async {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {(snapshot) in
                
                if let dictionary = snapshot.value as? [String:AnyObject]
                {
                    self.NavItemLabelView.text = dictionary["name"] as? String
                    
                }
                
            }, withCancel: nil)
        }
    }
    
    @IBAction func AllUsers(_ sender: Any)
    {
        let nav = self.storyboard?.instantiateViewController(withIdentifier: "AllUsersViewController")
        self.navigationController?.pushViewController(nav!, animated: true)
    }
    
    func FetchUserData()
    {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String:AnyObject]
            {
                
                let user = UserModel(dictionary: dictionary)
                user.uid = snapshot.key
                self.AllUsersArray.append(user)
            
            }
        }, withCancel: nil)
    }
}

extension MainPageViewController : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageTableCell
        let message = messages[indexPath.row]
    
        if let id = message.chatPartnerId()
        {
            let ref = Database.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                
                let dictionary = snapshot.value as? [String:AnyObject]
                    cell.NameLabel?.text = dictionary!["name"] as? String
                    cell.MessageLabelLabel.text = message.txtMsg
                    
                    if let seconds = message.date?.doubleValue {
                        let timestampDate = Date(timeIntervalSince1970: seconds)
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "hh:mm:ss a"
                        cell.DateLabel.text = dateFormatter.string(from: timestampDate)
                }
            }, withCancel: nil)
        }
       
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        let message = messages[indexPath.row]
        var userid : String?
        
        if Auth.auth().currentUser?.uid == message.toid
        {
            userid = message.fromid
        }
        else
        {
            userid = message.toid
        }
        
        let ref = Database.database().reference().child("users").child(message.chatPartnerId()!)
        ref.observe(.value, with: { (snapshot) in
            
            let userdetail = snapshot.value as? [String:AnyObject]
            
            for i in 0..<self.AllUsersArray.count
            {
                let element = self.AllUsersArray[i]
                if element.uid == userid
                {
                    let nav = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                    nav.userdic = userdetail!
                    nav.user = element
                    self.navigationController?.pushViewController(nav, animated: true)
                    break
                }
            }
        }, withCancel: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}

class MessageTableCell : UITableViewCell
{
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var MessageLabelLabel: UILabel!
    @IBOutlet weak var DateLabel: UILabel!
    
}
