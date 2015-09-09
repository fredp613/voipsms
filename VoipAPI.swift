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
        self.params = params
        //initialize a connection from request
    }
    
    func APIAuthenticatedRequest(completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let urlSession = NSURLSession.sharedSession()
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = self.httpMethod //httpMethod.rawValue
                
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var err: NSError?
        if httpMethod != "GET" { //httpMethod.rawValue != "GET"  {
            if let params = self.params {
                request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
            }
        }
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.new()) { (response, data, error) -> Void in
//            println(response)
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
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        println("did fail with error")
        println(error)
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        println("did receive response")
        println(response)
    }
    
    func connection(connection: NSURLConnection, willSendRequest request: NSURLRequest, redirectResponse response: NSURLResponse?) -> NSURLRequest? {

        println("did receive response")
        return request
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