//
//  ServiceController.swift
//  KYCMobile
//
//  Created by Jan ATAC on 24/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation


class ServiceController {

    let directoryURL:URL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)!
    
    func check(document:Document, success:@escaping (Score) -> Void, failure:@escaping(Error)-> Void){
        Service().check(document: document,success:{results in
            success(Score(with:results))
        },failure:{ error in
            print(error)
            failure(error)
        })
    }
    
    func createTmpStore(){
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR IN CREATING TMP STORE")
        }
    }
    
    // STORE THE DOC IN /TMP DIRECTORY
    func storeTmp(document:Document){
        let identifier      	=   ProcessInfo.processInfo.globallyUniqueString
        let fileName            =   String(format: "%@_%@", identifier, "document.txt")
        let directory           =   NSTemporaryDirectory()
        let writePath           =   directory.appending(fileName)
        
        document.info["URL"]    =   writePath
        document.info["NAME"]   =   fileName
        
        NSKeyedArchiver.archiveRootObject(document, toFile: writePath)
    }
    
    func getTmp(document:Document)->Document{
            let documentUnarchived:Document = NSKeyedUnarchiver.unarchiveObject(withFile: document.info["URL"] as! String ) as! Document
        return documentUnarchived
    }
    
    func cleanTmpStore(){
        do {
            try FileManager.default.removeItem(at: directoryURL)
        } catch {
            print("ERROR IN CLEANING TMP STORAGE")
        }
    }
    
    func getTmpImage()->NSData{
        return NSData()
    }
    
}
