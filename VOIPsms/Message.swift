//
//  Message.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-16.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

//1 = friend
//0 = me

class Message {
    var contact: String!
    var message: String!
    var type: Bool! 
    var date: String!
    var id: String!
    
    class func getMessagesFromAPI(moc: NSManagedObjectContext,completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        //from should be last date in core data
        let params = [
            "method" : "getSMS",
            "from" : "2015-04-11",
            "to" : dateFormatter.stringFromDate(NSDate()) as String,
            "limit" : "1000000"
        ]

        var coreMessages = CoreMessage.getMessages(moc, ascending: true).map({$0.id})
        VoipAPI.APIAuthenticatedRequest(httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil) { (responseObject, error) -> () in
            
            let json = responseObject
//            println(json)
            for (key: String, t: JSON) in json["sms"] {
                
                let contact = t["contact"].stringValue
                let id = t["id"].stringValue
                let typeStr = t["type"].stringValue
                var type : Bool
                let date = t["date"].stringValue
                let message = t["message"].stringValue
                var flagValue = String()
                if typeStr == "0" {
                    type = false
                    flagValue = message_status.DELIVERED.rawValue
                } else {
                    type = true
                    flagValue = message_status.PENDING.rawValue
                }
                let did = t["did"].stringValue
                
                if !contains(coreMessages, id) {
                    CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue)
                    
                    //check if contact exists
                    if CoreContact.isExistingContact(moc, contactId: contact) {
                        CoreContact.updateInManagedObjectContext(moc, contactId: contact, lastModified: date)
                    } else {
                        CoreContact.createInManagedObjectContext(moc, contactId: contact, lastModified: date)
                    }
                  
                }
            }
            return completionHandler(responseObject: json, error: nil)
        }
        
        
    }
    
    class func sendMessageAPI(contact: String, messageText: String, did: String,
        completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
            let params = [
                "method":"sendSMS",
                "did":did,
                "dst":contact,
                "message": messageText
            ]
                        
            VoipAPI.APIAuthenticatedRequest(httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil) { (responseObject, error) -> () in
                return completionHandler(responseObject: responseObject, error: nil)
            }

    }
    
    



}