//
//  UserModel.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/13/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit

class UserModel: NSObject {
    
    var uid : String?
    var name : String?
    var email : String?
    var password : String?
    var ProfileImageURL : String?
    
    init(dictionary:[AnyHashable: Any]) {
        self.name = dictionary["name"] as? String
        self.email = dictionary["email"] as? String
        self.ProfileImageURL = dictionary["ProfileImageURL"] as? String
        self.password = dictionary["password"] as? String
        self.uid = dictionary["id"] as? String
    }
}
