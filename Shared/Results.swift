//
//  Result.swift
//  KYCMobile
//
//  Created by Jan ATAC on 27/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation

class Results{

    var id:Int                  =   0
    var data:[String:Any]       =   [String:Any]()
    var score:Int               =   0
    
    init(){
        self.id  = Generator().newId()
    }
    
    init(with globalResult:GlobalResult){
        self.score = globalResult.scoring.confidenceIndex
    }


}
