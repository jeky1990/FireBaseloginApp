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

    @IBOutlet weak var StackView: UIStackView!
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var EnterMessage: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        SetKeyboardNotification()
        
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
        EnterMessage.text = ""
        let ref = Database.database().reference().child("Messages")
        let childref = ref.childByAutoId()
        let value = ["textMsg":EnterMessage.text!]
        childref.updateChildValues(value)
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
