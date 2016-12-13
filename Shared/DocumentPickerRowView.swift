//
//  DocumentPickerRowView.swift
//  KYCMobile
//
//  Created by Jan ATAC on 31/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import UIKit

class DocumentPickerRowView: UIView {

    @IBOutlet var rowTitle: UILabel!

    var rowData:String = "Default"
    
    override init(frame:CGRect) {
        super.init(frame:frame)

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

}
