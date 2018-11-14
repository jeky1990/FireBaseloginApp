//
//  ChatViewController.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/13/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    var user : UserModel?
    @IBOutlet weak var StackView: UIStackView!
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var EnterMessage: UITextField!
    
    @IBOutlet weak var NavItem: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetKeyboardNotification()
        NavItem.title = user?.name
        EnterMessage.becomeFirstResponder()
    }
    
    @IBAction func CancelAction(_ sender: Any)
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func SendButtonAction(_ sender: UIButton)
    {
        SendMessageUsingFirebase()
    }
    
    func SendMessageUsingFirebase()
    {
        let ref = Database.database().reference().child("Messages")
        let childref = ref.childByAutoId()
        let toid = user!.uid!
        let fromid = Auth.auth().currentUser!.uid
//        let date = Date()
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd/MM HH:mm"
//        let someDateTime = String(formatter.string(from: date))
        
        let someDateTime = Int(Date().timeIntervalSince1970)
        let value = ["textMsg":EnterMessage.text!,"toid":toid,"fromid":fromid,"date":someDateTime] as [String : Any]
        
        //childref.updateChildValues(value)
        
        childref.updateChildValues(value) { (error, ref) in
            if error != nil {
                print(error ?? "")
                return
            }
            
            guard let messageId = childref.key else { return }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromid).child(messageId)
            userMessagesRef.setValue(1)
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toid).child(messageId)
            recipientUserMessagesRef.setValue(1)
        }
        
        EnterMessage.text = ""
        EnterMessage.resignFirstResponder()
    }
    
    func SetKeyboardNotification()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyBoardWillShowChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyBoardWillHideChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func KeyBoardWillShowChange(notification: Notification)
    {
        let userInfo = notification.userInfo
        let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height + 10, right: 0.0)
        ScrollView.contentInset = contentInset
        ScrollView.scrollIndicatorInsets = contentInset
        ScrollView.scrollRectToVisible(StackView.frame, animated: true)
       
    }
    
    @objc func KeyBoardWillHideChange(notification: Notification)
    {
        let contentInset = UIEdgeInsets.zero
        ScrollView.contentInset = contentInset
        ScrollView.scrollIndicatorInsets = contentInset
    }
}

extension ChatViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        SendMessageUsingFirebase()
        return self.view.endEditing(true)
    }
}
