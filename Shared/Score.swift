//
//  Score.swift
//  KYCMobile
//
//  Created by Jan ATAC on 24/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation

class Score{

    var id:Int          =   0
    var rate:Double     =   0.0
    var amount:Int      =   0
    
    init(){
        self.id  = Generator().newId()
    }
    init(with results:Results){
        amount = results.score
    }
    
}
