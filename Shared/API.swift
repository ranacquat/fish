//
//  API.swift
//  KYCMobile
//
//  Created by Jan ATAC on 25/10/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import UIKit
import NVActivityIndicatorView


class API{
    
    static let notificationName = Notification.Name("DOC_ANALYSED")
    
    class func post(document:Document, success:@escaping (Results) -> Void, failure:@escaping(Error)-> Void){
        
        let server = URL(string: ("\(Constants().SERVER_URL)/detection"))
        
        API.upload(image: document.info["IMAGE"] as! Data, to: server!, success:{
            response in
            let results:Results = Results(with:response)
            success(results)
        },failure:{error in
            print(error)
            failure(error)
            API.doMockUpload(to: URL(string: ("\(Constants().MOCK_SERVER_URL)/post/document"))!,
                             success: {globalResult in
                                let results:Results = Results(with:globalResult)
                                success(results)
            },
                             failure: {error in
                                print(error)
                                failure(error)
            })
        })
    }
    
    class func upload(image:Data, to server:URL,success:@escaping (GlobalResult) -> Void, failure:@escaping (Error) -> Void){

        let activityData = ActivityData()
        
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData)
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(image, withName: "file", mimeType: "image/png")
                multipartFormData.append("CORINNE".data(using: .utf8)!, withName: "firstname")
                multipartFormData.append("BERTHIER".data(using: .utf8)!, withName: "lastname")
                multipartFormData.append("RIB".data(using: .utf8)!, withName: "type"    )
        },
            to: server,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.uploadProgress{ progress in
                        print("Upload Progress - Completed:             \(progress.fractionCompleted)")
                        print("Upload Progress - completedUnitCount:    \(progress.completedUnitCount)")
                        print("Upload Progress - totalUnitCount:        \(progress.totalUnitCount)")
                    }
                    upload.responseJSON { response in
                        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        guard response.result.isSuccess else {
                            debugPrint(response)
                            failure(response.result.error!)
                            return
                        }
                    }
                case .failure(let encodingError):
                    NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                    failure(encodingError)
                }
                
        }
        )
    }
    /*
    class func getAnalysisResult(success:@escaping (GlobalResult) -> Void, failure:@escaping (Error) -> Void){
        API.requestGETURL("\(Constants().SERVER_URL)/document/analysis", success: {
            result in
            success(result)
        }, failure: {(error) -> Void in
            print("getAnalysisResult - ERROR: \(error)")
            failure(error)
        })
    }
    
    class func requestGETURL(_ strURL: String, success:@escaping (GlobalResult) -> Void, failure:@escaping (Error) -> Void) {
        Alamofire.request(strURL).responseJSON { (responseObject) -> Void in
            
            print(responseObject)
            
            if responseObject.result.isSuccess {
                //let resJson = JSON(responseObject.result.value!)
                let globalResult = parse(json: responseObject.result.value as! [String : Any])
                success(globalResult)
            }
            if responseObject.result.isFailure {
                let error : Error = responseObject.result.error!
                failure(error)
            }
        }
    }
    
    class func getPostReturn(url:String, parameters:Parameters, success:@escaping (JSON) -> Void, failure:@escaping (Error) -> Void){

        Alamofire.request(url, method: .post, parameters:parameters, encoding: JSONEncoding.default).responseJSON { response in
            print("-------------->>> request    : \(response.request)")
            print("-------------->>> response   : \(response.response)")
            print("-------------->>> data       : \(response.data)")
            print("-------------->>> status     : \(response.response?.statusCode)")
            
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)")
            }
            switch response.result {
            case .success:
                print("Validation Successful")
                let resJson = JSON(response.result.value!)
                NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "ServerPush"), object: nil, queue: OperationQueue.main, using: {notification in
                    let parameters = ["key": "KYCMobile"]
                    
                    API.getPostReturn(url: "http://localhost:8080/results", parameters: parameters, success: {
                        (JSONResponse) -> Void in
                        print(JSONResponse)
                        
                        Alamofire.request("http://localhost:8080/json", method: .post, parameters:parameters, encoding: JSONEncoding.default).responseJSON { response in
                            debugPrint(response)
                            print("-------------->>> request: \(response.request)")
                            print("-------------->>> response: \(response.response)")
                            print("-------------->>> data: \(response.data)")
                            print("-------------->>> status : \(response.response?.statusCode)")
                            
                            
                            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                                print("Data: \(utf8Text)")
                            }
                            
                        }
                        
                        }, failure: {(error) -> Void in
                            print(error)                            
                    })
                })
                success(resJson)
            case .failure:
                let error : Error = response.result.error!
                print(error)
                failure(error)
            }
            
        }

    }
    
    */
    
    class func parse(json:[String: Any]) -> GlobalResult {
        return GlobalResult(json: json)!
    }
 
    class func doMockUpload(to server:URL,success:@escaping (GlobalResult) -> Void, failure:@escaping (Error) -> Void){
        
        //let mae:MaeWebSocket    =   MaeWebSocket(url: URL(string: "\(Constants().MOCK_SERVER_URL)/ws")!, protocols: nil)
        //let fileURL = Bundle.main.url(forResource: "ID_CARD", withExtension: "JPG")
        
        if let path = Bundle.main.path(forResource: "MAEResponse", ofType: "json") {
            do {
                let text = try String.init(contentsOfFile: path)
                
                if let data = text.data(using: String.Encoding.utf8) {
                        let dic:[String:AnyObject] = try JSONSerialization.jsonObject(with: data, options: []) as! [String:AnyObject]
                        let result:GlobalResult = API.parse(json: dic)
                        success(result)
                }
            }catch{}
        }
    }
}
