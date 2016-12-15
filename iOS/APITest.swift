//
//  APITest.swift
//  Fish
//
//  Created by Jan ATAC on 14/12/2016.
//  Copyright © 2016 RanAcquat. All rights reserved.
//

import XCTest
import Alamofire
@testable import Fish

class APITest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPOST() {
        let myExpectation = expectation(description: "AlamoFireLocally")

        let params: Parameters = ["data": ["https://upload.wikimedia.org/wikipedia/commons/7/71/Garibaldi_fish.jpg"]]

        let server = URL(string: ("\(Constants().SERVER_URL)/detection"))
        var request = URLRequest(url: server!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        //request.httpBody = try! JSONSerialization.data(withJSONObject: values)
        
        Alamofire.request(server!, method: .post, parameters:params, encoding: JSONEncoding.default).responseJSON { response in
            debugPrint(response)
            print("-------------->>> request: \(response.request)")
            print("-------------->>> response: \(response.response)")
            print("-------------->>> data: \(response.data)")
            print("-------------->>> status : \(response.response?.statusCode)")
            
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)")
            }
            
            myExpectation.fulfill()
            
        }
        
        
        waitForExpectations(timeout: 10.0, handler: nil)

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
