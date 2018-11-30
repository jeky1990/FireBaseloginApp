//
//  MessaheModel.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/14/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import Foundation
import Firebase

class MessageModel : NSObject {
    
    let toid : String?
    let fromid : String?
    let txtMsg : String?
    let date : NSNumber?
    let imageUrl: String?
    
    init(dictionary: [AnyHashable:Any]) {
        
        self.toid = dictionary["toid"] as? String
        self.fromid = dictionary["fromid"] as? String
        self.date = dictionary["date"] as? NSNumber
        self.txtMsg = dictionary["textMsg"] as? String
        self.imageUrl = dictionary["imageUrl"] as? String
    }
    
    func chatPartnerId()-> String?
    {
        return fromid == Auth.auth().currentUser?.uid ? toid : fromid
    }

}
