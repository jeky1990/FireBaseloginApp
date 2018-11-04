//
//  ViewController.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/3/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import MKProgress

class ViewController: UIViewController,UIImagePickerControllerDelegate {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var LoginRegister: UISegmentedControl!
    @IBOutlet weak var NameTF: UITextField!
    @IBOutlet weak var EmailTF: UITextField!
    @IBOutlet weak var PasswordTF: UITextField!
    @IBOutlet weak var LogInOrSignup: UIButton!
    @IBOutlet weak var ProfileImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        LoginRegister.selectedSegmentIndex = 0
        SetSelectedIndex()
        SetKeyboardNotification()
        Tapgesture()
        SetProfilImageView()
    }
    
    func Alert(title:String?,message:String,prefferedstyle:UIAlertController.Style)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: prefferedstyle)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
      
    }
    
    func SetSelectedIndex()
    {
        if LoginRegister.selectedSegmentIndex == 0
        {
            ProfileImage.isHidden = true
            NameTF.isHidden = true
            LogInOrSignup.setTitle("Sign In", for: .normal)
        }
        else
        {
            ProfileImage.isHidden = false
            NameTF.isHidden = false
            LogInOrSignup.setTitle("Save", for: .normal)
        }
    }
    
    @IBAction func LoginRegisterAction(_ sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 0
        {
            ProfileImage.isHidden = true
            NameTF.isHidden = true
            LogInOrSignup.setTitle("Sign In", for: .normal)
            ClearTextFieldf()
        }
        else
        {
            ProfileImage.isHidden = false
            NameTF.isHidden = false
            LogInOrSignup.setTitle("Save", for: .normal)
            ClearTextFieldf()
        }
    }
    
    func SetProfilImageView()
    {
        ProfileImage.layer.cornerRadius = self.ProfileImage.frame.width/2
        ProfileImage.clipsToBounds = true
        ProfileImage.image = UIImage(named: "demoprofile")
    }
    
    @IBAction func LoginSaveAction(_ sender: Any)
    {
        PasswordTF.resignFirstResponder()
        if LoginRegister.selectedSegmentIndex == 0
        {
            guard let email = EmailTF.text,
            let password = PasswordTF.text else
            {
                Alert(title: "Error", message: "Please fill All Detail", prefferedstyle: .alert)
                return
            }
            
            MKProgress.show()
            
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if error != nil
                {
                    self.Alert(title: "Error", message: "\(String(describing: error!.localizedDescription))", prefferedstyle: .alert)
                }
                
             MKProgress.hide()
            
                let navigation = self.storyboard?.instantiateViewController(withIdentifier: "MainPageViewController")
                self.navigationController?.pushViewController(navigation!, animated: true)
            
            }
        }
        else
        {
            
        guard let email = EmailTF.text,
            let password = PasswordTF.text,
            let name = NameTF.text else
        {
            print("not valid form")
            return
        }
            
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                
                if error != nil
                {
                    self.Alert(title: "Error", message: "\(String(describing: error!.localizedDescription))", prefferedstyle: .alert)
                }
                
                let ref = Database.database().reference(fromURL: "https://fcmdatabase-63dd0.firebaseio.com/")
                
                guard (user?.user.uid) != nil else
                {
                    self.Alert(title: "Error", message: "\(String(describing: error!.localizedDescription))", prefferedstyle: .alert)
                    return
                }
                
                MKProgress.show()
                let userreferences = ref.child("users").child((user?.user.uid)!);           let values = ["name":name,"email":email,"password":password]
                userreferences.updateChildValues(values, withCompletionBlock: { (error, ref) in
                            if error != nil
                            {
                                self.Alert(title: "Error", message: "\(String(describing: error!.localizedDescription))", prefferedstyle: .alert)
                            }
                 
                            
                    print("Save Data Successfully with userId : \(String(describing: user!.user.uid))")
                    MKProgress.hide()
                    self.HandleLogout()
                    self.LoginRegister.selectedSegmentIndex = 0
                    self.SetSelectedIndex()
                    self.ClearTextFieldf()
                    
                    })
                })
            }
        
    }
    
    func HandleLogout()
    {
        do
        {
            try Auth.auth().signOut()
        }catch let logouterror{
            print(logouterror)
        }
    }
    
    func ClearTextFieldf()
    {
        NameTF.text = ""
        EmailTF.text = ""
        PasswordTF.text = ""
        if LoginRegister.selectedSegmentIndex == 0
        {
            EmailTF.becomeFirstResponder()
        }
        else
        {
            NameTF.becomeFirstResponder()
        }
    }
    
    func Tapgesture()
    {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.CreateImagePickerController))
        tap.numberOfTapsRequired = 1
        ProfileImage.isUserInteractionEnabled = true
        self.ProfileImage.addGestureRecognizer(tap)
    }
    
    @objc func CreateImagePickerController()
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
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
        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height + 30, right: 0.0)
        ScrollView.contentInset = contentInset
        ScrollView.scrollIndicatorInsets = contentInset
        ScrollView.scrollRectToVisible(PasswordTF.frame, animated: true)
        ScrollView.scrollRectToVisible(NameTF.frame, animated: true)
        ScrollView.scrollRectToVisible(EmailTF.frame, animated: true)
    }
    
    @objc func KeyBoardWillHideChange(notification: Notification)
    {
        let contentInset = UIEdgeInsets.zero
        ScrollView.contentInset = contentInset
        ScrollView.scrollIndicatorInsets = contentInset
    }
    
}

extension ViewController : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        return self.mainView.endEditing(true)
    }
}

extension ViewController:UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let Image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        ProfileImage.image = Image
        self.dismiss(animated: true, completion: nil)
    }
}

