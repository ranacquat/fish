//
//  Service.swift
//  KYCMobile
//
//  Created by Jan ATAC on 24/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation
import UIKit

class Service{

    func check(document:Document, success:@escaping (Results) -> Void, failure:@escaping(Error)-> Void){
        API.post(document: document, success:{
            result in
            success(result)
        },failure:{error in
            failure(error)
        })
    }
    
    func store(image:UIImage, key:String) -> Bool {
        UserDefaults.standard.set(UIImagePNGRepresentation(image), forKey:key)
        return true
    }
    
}
