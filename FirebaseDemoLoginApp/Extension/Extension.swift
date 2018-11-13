//
//  Extension.swift
//  FirebaseDemoLoginApp
//
//  Created by macbook on 11/13/18.
//  Copyright © 2018 macbook. All rights reserved.
//

import UIKit

let imagecache = NSCache<AnyObject, AnyObject>()

extension UIImageView
{
    func LoadImageUsingCache(Urlstring:String)
    {
        self.image = nil
        
        if let cachedImage = imagecache.object(forKey: Urlstring as AnyObject) as? UIImage
        {
            self.image = cachedImage
            return
        }
        
        let URL = NSURL(string: Urlstring)
        let request = URLRequest(url: URL! as URL)
        let session = URLSession.shared
        
        session.dataTask(with: request) { (data, responce, error) in
            if error != nil
            {
                print(error?.localizedDescription as Any)
                return
            }
            DispatchQueue.main.async {
                let downloadImage = UIImage(data: data!)
                imagecache.setObject(downloadImage!, forKey: Urlstring as AnyObject)
                self.image = downloadImage
            }
            }.resume()
    }
}
