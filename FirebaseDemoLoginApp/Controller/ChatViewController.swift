//
//  ChatViewController.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/13/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var ImagePickerView: UIImageView!
    

    var user : UserModel? = nil
    var messages = [MessageModel](){
        didSet{
            MsgTbl.reloadData()
            if messages.count >= 2
            {

                let indexPath = IndexPath(row: messages.count-1, section: 0)
                self.MsgTbl.scrollToRow(at: indexPath,
                                    at: UITableView.ScrollPosition.bottom, animated: false)
            }
        }
    }
    var userdic : [String:AnyObject] = [:]
    var AllUsersArray : [UserModel] = []
    
    @IBOutlet weak var MainView: UIView!
    
    @IBOutlet weak var ScrollView: UIScrollView!
    @IBOutlet weak var EnterMessage: UITextField!
    @IBOutlet weak var MsgTbl: UITableView!
    @IBOutlet weak var NavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FetchUserData()
        SwipeGesture()
        TapGesture()
        SetKeyboardNotification()
        NavItem.title = "To : \(String(describing: userdic["name"] as! String))"
        observeMessages()
        MsgTbl.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        MainView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        MsgTbl.separatorColor = UIColor.clear
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
    func TapGesture()
    {
        ImagePickerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.OpenGallery)))
        ImagePickerView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(HideKeyboard))
        tap.numberOfTapsRequired = 1
        self.MsgTbl.addGestureRecognizer(tap)
    }
    
    @objc func OpenGallery(sender:UITapGestureRecognizer)
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage : UIImage?
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        {
            selectedImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        {
            selectedImage = originalImage
        }
        
        if let selectedImageforUpload = selectedImage
        {
            UploadtoFireBaseUsingImages(image: selectedImageforUpload)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func UploadtoFireBaseUsingImages(image:UIImage)
    {
        let imagename = NSUUID().uuidString
        let ref = Storage.storage().reference().child("\(imagename).jpg")
        
        if let uploadData = image.jpegData(compressionQuality: 0.1) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:", error!)
                    return
                }
                
                ref.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print(err)
                        return
                    }
                   
                    self.sendMessageWithImageUrl((url?.absoluteString)!)
                    self.MsgTbl.reloadData()
                })
                
            })
        }
    }
    
    fileprivate func sendMessageWithImageUrl(_ imageUrl: String) {
        
        let ref = Database.database().reference().child("Messages")
        let childRef = ref.childByAutoId()
        let toId = user?.uid
        let fromId = Auth.auth().currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let values = ["imageUrl": imageUrl, "toid": toId!, "fromid": fromId, "date": timestamp] as [String : Any]
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
            guard let messageId = childRef.key else { return }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(messageId)
            userMessagesRef.setValue(1)
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId!).child(messageId)
            recipientUserMessagesRef.setValue(1)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func HideKeyboard(sender:UITapGestureRecognizer)
    {
        EnterMessage.resignFirstResponder()
    }
    
    func SwipeGesture()
    {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.MsgTbl.addGestureRecognizer(swipeRight)
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
        
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                EnterMessage.resignFirstResponder()
                
            default:
                break
            }
        }
    }
    
    func observeMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        let userMessagesRef = Database.database().reference().child("user-messages").child(uid)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("Messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                let message = MessageModel(dictionary: dictionary)
                
                    if message.chatPartnerId() == self.user?.uid {
                        
                        self.messages.append(message)
                    }
                    else 
                    {
                        self.messages.append(message)
                    }
               
    
            }, withCancel: nil)
        }, withCancel: nil)
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
        if EnterMessage.text != ""
        {
            let ref = Database.database().reference().child("Messages")
            let childref = ref.childByAutoId()
            let toid = user?.uid
            let fromid = Auth.auth().currentUser!.uid
            
            let someDateTime = Int(Date().timeIntervalSince1970)
            let value = ["textMsg":EnterMessage.text!,"toid":toid!,"fromid":fromid,"date":someDateTime] as [String : Any]
        
        //childref.updateChildValues(value)
        
            childref.updateChildValues(value) { (error, ref) in
                if error != nil {
                    print(error ?? "")
                    return
                }
            
            guard let messageId = childref.key else { return }
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromid).child(messageId)
            userMessagesRef.setValue(1)
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toid!).child(messageId)
            recipientUserMessagesRef.setValue(1)
                
//                if self.messages.count >= 2
//                {
//                    let indexPath = IndexPath(row: self.messages.count-1, section: 0)
//                    self.MsgTbl.scrollToRow(at: indexPath,
//                                            at: UITableView.ScrollPosition.bottom, animated: false)
//                }
        }
            EnterMessage.text = ""
            EnterMessage.becomeFirstResponder()
        }
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
        let keyboardDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height + 10, right: 0.0)
        ScrollView.contentInset = contentInset
        ScrollView.scrollIndicatorInsets = contentInset
        ScrollView.scrollRectToVisible(EnterMessage.frame, animated: true)
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
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
        if EnterMessage.text != ""
        {
            SendMessageUsingFirebase()
        }
        return self.view.endEditing(true)
    }
}

extension ChatViewController:UITableViewDelegate,UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatCell
        
        cell.CreateCellView()
        cell.CreateLeftImageview()
        cell.CreateRightImageview()
        
        //cell.CreateSendMessageView()
        
        let message = messages[indexPath.row]
        
        
        //cell.Msglabel.text = "\("  ")\(message.txtMsg!)\("    ")"
        //cell.Msglabel.textColor = UIColor(red: 0, green: 137/255, blue: 250/255, alpha: 1)
      
        cell.backgroundColor = UIColor.clear
        cell.cellview.backgroundColor = UIColor.clear

        SetupCell(cell: cell, message: message)
        
        /*let pattern = "\\s+|\\S+"
        let mutable = NSMutableAttributedString(string: cell.Msglabel.text!)
        var startIndex = cell.Msglabel.text!.startIndex
        while let range = cell.Msglabel.text!.range(of: pattern, options: .regularExpression, range: startIndex..<cell.Msglabel.text!.endIndex) {
            mutable.addAttribute(.backgroundColor, value: UIColor(red: 0, green: 137/255, blue: 250/255, alpha: 1), range: NSRange(range, in: cell.Msglabel.text!))
            startIndex = range.upperBound
        }
        cell.Msglabel.attributedText = mutable*/
        
        return cell
    }
    
    private func SetupCell(cell:ChatCell,message:MessageModel)
    {
        if let ProfileImageUrl = self.user?.ProfileImageURL
        {
            let url = URL(string: ProfileImageUrl)
            let resource = ImageResource(downloadURL: url!, cacheKey: self.user?.ProfileImageURL)
            cell.LeftProfileImageView.kf.setImage(with: resource)
        }
        
        var currentuid : String?
        currentuid = Auth.auth().currentUser?.uid
        
        for i in 0...AllUsersArray.count
        {
            let element = AllUsersArray[i]
            if  element.uid == currentuid
            {
                let url = URL(string: element.ProfileImageURL!)
                let resource = ImageResource(downloadURL: url!, cacheKey: element.ProfileImageURL)
                cell.RightProfileImageView.kf.setImage(with: resource)
                break
            }
        }
        
        if message.imageUrl == nil && message.txtMsg != nil
        {
            if message.fromid == Auth.auth().currentUser?.uid
            {
                cell.CreateMessagelabel()
                cell.RemoveSendImageView()
                cell.MessageLabel.text = message.txtMsg
                cell.MessageLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                cell.MessageLabel.textAlignment = .right
                cell.LeftProfileImageView.isHidden = true
                cell.RightProfileImageView.isHidden = false
            }
            else
            {
                cell.CreateMessagelabel()
                cell.RemoveSendImageView()
                cell.MessageLabel.text = message.txtMsg
                cell.MessageLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                cell.MessageLabel.textAlignment = .left
                cell.LeftProfileImageView.isHidden = false
                cell.RightProfileImageView.isHidden = true
            }
        }
        else if message.imageUrl != nil && message.txtMsg == nil
        {
            if message.fromid == Auth.auth().currentUser?.uid
            {
                if let messageImageUrl = message.imageUrl
                {
                    cell.fromid = message.fromid!
                    cell.CreateSendMessageView()
                    cell.RemoveMessageLabel()
                    let url = URL(string: messageImageUrl)
                    cell.SendImageView.contentMode = .scaleAspectFit
                    let resource = ImageResource(downloadURL: url!, cacheKey: messageImageUrl)
                    cell.SendImageView.kf.setImage(with: resource)
                    cell.LeftProfileImageView.isHidden = true
                    
                    cell.RightProfileImageView.isHidden = false
                }
            }
            else
            {
                if let messageImageUrl = message.imageUrl
                {
                    cell.CreateSendMessageView()
                    cell.RemoveMessageLabel()
                    let url = URL(string: messageImageUrl)
                    cell.SendImageView.contentMode = .scaleAspectFit
                    let resource = ImageResource(downloadURL: url!, cacheKey: messageImageUrl)
                    cell.SendImageView.kf.setImage(with: resource)
                    cell.LeftProfileImageView.isHidden = false
                    
                    cell.RightProfileImageView.isHidden = true
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
        let message = messages[indexPath.row]

        if message.imageUrl == nil && message.txtMsg != nil
        {
            return UITableView.automaticDimension
        }
        else //if message.imageUrl != nil && message.txtMsg == nil
        {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
}

class ChatCell : UITableViewCell
{
    var fromid : String? = nil
    let cellview: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let LeftProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "demoprofile")
        return imageView
    }()
    
    
    let RightProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "demoprofile")
        return imageView
    }()
    
    var MessageLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 17)
        label.text = "sdhjfksjadhfkgjf askdjhfakjhfkdjhaksdf sdkhjfksjhdf sadfhkljshdfkjhakjhsdfjkhsahjkf skajadfhjskjhfa dfasdhfkhj"
        label.numberOfLines = 0
        
        return label
        
    }()
    
    let SendImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "demoprofile")
        return imageView
    }()

    func CreateCellView()
    {
        self.addSubview(cellview)
        
        NSLayoutConstraint.activate([
            
            cellview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            cellview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            cellview.widthAnchor.constraint(equalTo: self.widthAnchor),
            cellview.heightAnchor.constraint(equalTo: self.heightAnchor)
            
            ])
    }

    func CreateLeftImageview()
    {
        cellview.addSubview(LeftProfileImageView)
        
        NSLayoutConstraint.activate([
            
            LeftProfileImageView.leftAnchor.constraint(equalTo: cellview.leftAnchor, constant: 5),
            LeftProfileImageView.topAnchor.constraint(equalTo: cellview.topAnchor, constant: 5),
            LeftProfileImageView.widthAnchor.constraint(equalToConstant: 25),
            LeftProfileImageView.heightAnchor.constraint(equalToConstant: 25)
            
            ])
    }
    
    func CreateRightImageview()
    {
        cellview.addSubview(RightProfileImageView)
        
        NSLayoutConstraint.activate([
            
            RightProfileImageView.rightAnchor.constraint(equalTo: cellview.rightAnchor, constant: -5),
            RightProfileImageView.topAnchor.constraint(equalTo: cellview.topAnchor, constant: 5),
            RightProfileImageView.widthAnchor.constraint(equalToConstant: 25),
            RightProfileImageView.heightAnchor.constraint(equalToConstant: 25)
            
            ])
    }
    
    func CreateMessagelabel()
    {
        cellview.addSubview(MessageLabel)
        NSLayoutConstraint.activate([
            
            MessageLabel.leftAnchor.constraint(equalTo: LeftProfileImageView.rightAnchor, constant: 10),
            MessageLabel.topAnchor.constraint(equalTo: cellview.topAnchor, constant: 5),
            MessageLabel.rightAnchor.constraint(equalTo: RightProfileImageView.leftAnchor, constant: -10),
            MessageLabel.bottomAnchor.constraint(equalTo: cellview.bottomAnchor, constant: -5)
            
            ])
    }
    
    var ImageviewLeftAnchor : NSLayoutConstraint?
    var ImageviewRightAnchor : NSLayoutConstraint?
    
    func CreateSendMessageView()
    {
        cellview.addSubview(SendImageView)
        
        if fromid == Auth.auth().currentUser?.uid
        {
            ImageviewLeftAnchor = SendImageView.leftAnchor.constraint(equalTo: LeftProfileImageView.rightAnchor, constant: 100)
            ImageviewLeftAnchor?.isActive = true
        
            ImageviewRightAnchor = SendImageView.rightAnchor.constraint(equalTo: RightProfileImageView.leftAnchor, constant: 10)
            ImageviewRightAnchor?.isActive = true
        }
        else
        {
            ImageviewLeftAnchor = SendImageView.leftAnchor.constraint(equalTo: LeftProfileImageView.rightAnchor, constant: 10)
            ImageviewLeftAnchor?.isActive = true
            
            ImageviewRightAnchor = SendImageView.rightAnchor.constraint(equalTo: RightProfileImageView.leftAnchor, constant: 100)
            ImageviewRightAnchor?.isActive = true
        }
        
        NSLayoutConstraint.activate([
            
            SendImageView.topAnchor.constraint(equalTo: cellview.topAnchor, constant: 5),
            
            SendImageView.bottomAnchor.constraint(equalTo: cellview.bottomAnchor, constant: -5)
            
            ])
    }
    
    func RemoveMessageLabel()
    {
        self.MessageLabel.removeFromSuperview()
    }
    
    func RemoveSendImageView()
    {
        self.SendImageView.removeFromSuperview()
    }
}
