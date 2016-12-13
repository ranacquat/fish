//
//  DocumentController.swift
//  KYCMobile
//
//  Created by Jan ATAC on 24/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation

class DocumentController{

    var document:Document = Document()
    
    func create() -> Document {
        document.id = Generator().newId()
        document.isValid    =   false
        document.type       =   "UNKNOWN"
        return document
    }
    
    func retrieve() -> Document {
        return document
    }
    
    func update(document:Document) -> Document{
        return Document()
    }
    
    func delete(document:Document) -> Bool {
        return true
    }
    
}
