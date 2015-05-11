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
    var type: NSNumber!
    var date: String!
    var id: String!
    
    init(contact: String, message: String, type: NSNumber, date: String, id:String) {
        self.contact = contact
        self.message = message
        self.type = type
        self.date = date
        self.id = id
        
    }
    
    class func getMessagesFromAPI(moc: NSManagedObjectContext, from: String!, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        //from should be last date in core data
        
        var fromStr = String()
        if from != nil {
            fromStr = from!
        } else {
            fromStr = CoreDID.getSelectedDID(moc)!.registeredOn
        }
        
        let params = [
            "method" : "getSMS",
            "from" : fromStr.strippedDateFromString(),
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
                
                if CoreMessage.isExistingMessageById(moc, id: id) == false && CoreDeleteMessage.isDeletedMessage(moc, id: id) == false  {
                    CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (responseObject, error) -> () in
                        //check if contact exists
                        if CoreContact.isExistingContact(moc, contactId: contact) {
                            CoreContact.updateInManagedObjectContext(moc, contactId: contact, lastModified: date)
                        } else {
                            CoreContact.createInManagedObjectContext(moc, contactId: contact, lastModified: date)
                        }
                    })
                }
            }
            return completionHandler(responseObject: json, error: nil)
        }
        
        
    }
    
    class func getIncomingMessagesFromAPI(moc: NSManagedObjectContext, did: String, contact: String, from: String!,  completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        //from should be last date in core data
        var fromStr = String()
        if from != nil {
            fromStr = from
        } else {
            fromStr = CoreDID.getSelectedDID(moc)!.registeredOn
        }

        
        let params = [
            "method" : "getSMS",
            "from" : fromStr.strippedDateFromString(),
            "type" : "1",
            "did" : did,
            "contact" : contact,
            "to" : dateFormatter.stringFromDate(NSDate()) as String,
            "limit" : "1000000"
        ]
        
        
        VoipAPI.APIAuthenticatedRequest(httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil) { (responseObject, error) -> () in
            
            let json = responseObject
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
                if CoreMessage.isExistingMessageById(moc, id: id) == false {
                    CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (responseObject, error) -> () in
                        //check if contact exists
                        if CoreContact.isExistingContact(moc, contactId: contact) {
                            CoreContact.updateInManagedObjectContext(moc, contactId: contact, lastModified: date)
                        } else {
                            CoreContact.createInManagedObjectContext(moc, contactId: contact, lastModified: date)
                        }
                    })
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
    
    class func deleteMessagesFromAPI(ids: [String], completionHandler: (responseObject: Bool, error: NSError?)->()) {
        
        for id in ids {
            let params = [
                "method":"deleteSMS",
                "id":id
            ]
            VoipAPI.APIAuthenticatedRequest(httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil) { (responseObject, error) -> () in
                    println(responseObject)
            }
        }
        return completionHandler(responseObject: true, error: nil)
       

    }
    
    



}