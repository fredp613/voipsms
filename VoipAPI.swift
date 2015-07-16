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

class VoipAPI : NSObject, UIAlertViewDelegate {
    
    class func APIAuthenticatedRequest(httpMethod: httpMethodEnum, url: String, params: [String:String!]?, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let urlSession = NSURLSession.sharedSession()
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = httpMethod.rawValue
                
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var err: NSError?
        if httpMethod.rawValue != "GET"  {
            if let params = params {
                request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
            }
        }

        
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            
            if let err = error {

                return
            }
            
            if error == nil {
                
                if let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) {
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
    }
    
    class func APIAuthenticatedRequestSync(httpMethod: httpMethodEnum, url: String, params: [String:String!]?, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let urlSession = NSURLSession.sharedSession()
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = httpMethod.rawValue
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var err: NSError?
        if httpMethod.rawValue != "GET"  {
            if let params = params {
                request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
            }
        }
        

        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            if let err = error {

//                let alert = UIAlertView(title: "Something went wrong please try again", message: "Connection error", delegate: self, cancelButtonTitle: "Ok")
//                alert.show()
                return
            }
            
            if error == nil {
                
                if let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) {
                    let parsedData = JSON(json!)
                    return completionHandler(responseObject: parsedData, error: nil)
                } else {
                    return completionHandler(responseObject: nil, error: error)
                }
            }
            
        }
    }
}