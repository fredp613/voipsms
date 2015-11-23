//
//  VoipAPI.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum httpMethodEnum : String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
    case UPDATE = "UPDATE"
}

class VoipAPI : NSObject, UIAlertViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var connection : NSURLConnection!
    var url: String!
    var params : [String:AnyObject]?
    var httpMethod: String!
    
    
    init(httpMethod: httpMethodEnum, url: String, params: [String:AnyObject]!) {
        super.init()
        self.url = url
        self.httpMethod = httpMethod.rawValue
        if params != nil {
            self.params = params
        }
        
    }
    
    func APIAuthenticatedRequest(completionHandler: (responseObject: JSON, error: NSError?) -> ()) {

        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = self.httpMethod //httpMethod.rawValue
                
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var err: NSError?
        if httpMethod != "GET" {
            if params != nil {
                do {
                    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params!, options: [])
                } catch let error as NSError {
                    err = error
                    print(err)
                    request.HTTPBody = nil
                }
            }
        }
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in

            if (error != nil) {
                print(error)
                return
            }

            if let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) {
                let parsedData = JSON(json!)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    return completionHandler(responseObject: parsedData, error: nil)
                })

            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    return completionHandler(responseObject: nil, error: error)
                })
            }
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        print("did fail with error")
        print(error)
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        print("did receive response")
//        print(response)
    }
    
    func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {

        print("did receive response")
        return request
    }
    

    
    class func APIAuthenticatedRequestSync(httpMethod: httpMethodEnum, url: String, params: [String:String!]?, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = httpMethod.rawValue
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var err: NSError?
        if httpMethod.rawValue != "GET"  {
            if let params = params {
                do {
                    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(params, options: [])
                } catch let error as NSError {
                    err = error
                    print(err)
                    request.HTTPBody = nil
                }
            }
        }
        

        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            if error != nil {
                return
            }
            if let json: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) {
                let parsedData = JSON(json!)
                return completionHandler(responseObject: parsedData, error: nil)
            } else {
                return completionHandler(responseObject: nil, error: error)
            }
        }
    }
}