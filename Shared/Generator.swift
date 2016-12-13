//
//  Generator.swift
//  KYCMobile
//
//  Created by Jan ATAC on 25/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation

struct Generator{
    
    func newId()->Int{
        return Int(arc4random_uniform(100000))
    }
    
}
