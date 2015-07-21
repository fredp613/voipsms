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
    var fromAppDelegate: Bool!
    
    init(contact: String, message: String, type: NSNumber, date: String, id:String, fromAppDelegate: Bool) {
        self.contact = contact
        self.message = message
        self.type = type
        self.date = date
        self.id = id
        self.fromAppDelegate = fromAppDelegate
    }

    
    class func getMessagesFromAPI(fromAppDelegate: Bool, moc: NSManagedObjectContext, from: String!, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        //from should be last date in core data
        
        var fromStr = String()
        if from != nil {
            fromStr = from!
        } else {
            fromStr = CoreDID.getSelectedDID(moc)!.registeredOn
        }
        var params = [String : String]()
        
        if let currentUser = CoreUser.currentUser(moc) {
            
            var calendar: NSCalendar = NSCalendar.currentCalendar()
            let strDate = dateFormatter.stringFromDate(NSDate())
            // Replace the hour (time) of both dates with 00:00
            let date1 : NSDate = dateFormatter.dateFromString(fromStr)!
            let date2 : NSDate = dateFormatter.dateFromString(strDate)!
            
            let flags = NSCalendarUnit.CalendarUnitDay
            let components = calendar.components(flags, fromDate: date1, toDate: date2, options: nil)
            
            if components.day > 91 {
                fromStr = dateFormatter.stringFromDate(date2.dateByAddingTimeInterval(60*60*24*(-91)))
            }
            if (currentUser.initialLogon.boolValue == true) || (currentUser.initialLoad.boolValue == true) {
                params = [
                    "method" : "getSMS",
                    "from" : fromStr,
                    "to" : dateFormatter.stringFromDate(NSDate()) as String,
                    "limit" : "500"
                ]
            } else {
                params = [
                    "method" : "getSMS",
                    "limit" : "1"
                ]
            }
        }
        var coreMessages = CoreMessage.getMessages(moc, ascending: true).map({$0.id})

        VoipAPI.APIAuthenticatedRequest(httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil) { (responseObject, error) -> () in
          
            let json = responseObject
            for (key: String, t: JSON) in json["sms"] {
                let contact = t["contact"].stringValue
                let id = t["id"].stringValue
                let typeStr = t["type"].stringValue
                var type : Bool
                let date = t["date"].stringValue
                let message = t["message"].stringValue.stringByReplacingOccurrencesOfString("?", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                var flagValue = String()
                if typeStr == "0" {
                    type = false
                    flagValue = message_status.DELIVERED.rawValue
                } else {
                    type = true
                    if let currentUser = CoreUser.currentUser(moc) {
                        flagValue = message_status.DELIVERED.rawValue
                        if currentUser.initialLogon == 1 || currentUser.initialLogon.boolValue == true {
                            flagValue = message_status.READ.rawValue
                        }
                    } else {
                        flagValue = message_status.PENDING.rawValue
                    }
                    
                }
                let did = t["did"].stringValue
                
                if CoreMessage.isExistingMessageById(moc, id: id) == false && CoreDeleteMessage.isDeletedMessage(moc, id: id) == false  {
                    CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (t, error) -> () in
                        println("message created")

                        if let contactOfMessage = CoreContact.currentContact(moc, contactId: contact) {
                            var formatter1: NSDateFormatter = NSDateFormatter()
                            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                            let parsedDate: NSDate = formatter1.dateFromString(date)!
                            contactOfMessage.lastModified = parsedDate
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                CoreContact.updateContactInMOC(moc)
//                            })
                        } else {
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                CoreContact.createInManagedObjectContext(moc, contactId: contact, lastModified: date)
//                            })
                        }

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if (type && (UIApplication.sharedApplication().applicationState == UIApplicationState.Background)) {
                                println("trying to send push")
                                Message.sendPushNotification(contact, message: message)
                            }
                        })
                       
                    })
                }
            }
            return completionHandler(responseObject: json, error: nil)
        }
    }
    

    
    
    class func sendPushNotification(contact: String, message: String) {
        let moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        var contactStr = contact
        if let cu = CoreContact.currentContact(moc, contactId: contact) {
            if cu.fullName != nil {
                contactStr = cu.fullName
            } else {
                contactStr = contact.northAmericanPhoneNumberFormat()
            }
        }
        var boldText  = contactStr
        var attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(15)]
        var boldString = NSMutableAttributedString(string:boldText, attributes:attrs)
        var localNotification = UILocalNotification()
        localNotification.alertBody = "\(contactStr)\r\n\(message)"
//        UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
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
        
        var params = [String:String]()
        
        if let currentUser = CoreUser.currentUser(moc) {

            if (currentUser.initialLogon.boolValue == true) || (currentUser.initialLoad.boolValue == true) {
                params = [
                    "method" : "getSMS",
                    "from" : fromStr.strippedDateFromString(),
                    "type" : "1",
                    "did" : did,
                    "contact" : contact,
                    "to" : dateFormatter.stringFromDate(NSDate()) as String,
                    "limit" : "500"
                ]
            } else {
                params = [
                    "method" : "getSMS",
                    "type" : "1",
                    "did" : did,
                    "contact" : contact
                ]
            }
            
            
        }

        
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
                    flagValue = message_status.READ.rawValue
                }
                let did = t["did"].stringValue
                if CoreMessage.isExistingMessageById(moc, id: id) == false && CoreDeleteMessage.isDeletedMessage(moc, id: id) == false  {

                    CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (t, error) -> () in
                        
//                        Message.sendPushNotification(contact, message: message)
                        
                        //check if contact exists

                        if let contactOfMessage = CoreContact.currentContact(moc, contactId: contact) {
                            var formatter1: NSDateFormatter = NSDateFormatter()
                            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                            let parsedDate: NSDate = formatter1.dateFromString(date)!
                            contactOfMessage.lastModified = parsedDate
                            CoreContact.updateContactInMOC(moc)
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
                if error != nil {
                    return completionHandler(responseObject: responseObject, error: error)
                } else {
                    return completionHandler(responseObject: responseObject, error: nil)
                }
                
            }
    }
    
    class func deleteMessagesFromAPI(ids: [String]!, completionHandler: (responseObject: Bool, error: NSError?)->()) {
        
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