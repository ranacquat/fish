//
//  Document.swift
//  KYCMobile
//
//  Created by Jan ATAC on 24/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation

class Document:NSObject, NSCoding{

    var id:Int                  =   0
    var type:String             =   ""
    var info:[String:Any]       =   [String:Any]()
    var isValid:Bool            =   false

    override convenience init(){
        self.init(id:Generator().newId(), type:"", info:[String:Any](), isValid:false)
    }
 
    init(id:Int, type:String, info:[String:Any], isValid:Bool){
        self.id                 =   id
        self.type               =   type
        self.info               =   info
        self.isValid            =   isValid
    }
    
    required convenience init(coder:NSCoder) {
        let id                  =   coder.decodeInteger(forKey:"id")    
        let type                =   coder.decodeObject(forKey: "type")  as! String
        let info                =   coder.decodeObject(forKey: "info")  as! [String:Any]
        let isValid             =   coder.decodeBool(forKey: "isValid") as  Bool
        
        self.init(id:id, type:type, info:info, isValid:isValid)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id,          forKey: "id")
        aCoder.encode(self.type,        forKey: "type")
        aCoder.encode(self.info,        forKey: "info")
        aCoder.encode(self.isValid,     forKey: "isValid")
    }
    
}
