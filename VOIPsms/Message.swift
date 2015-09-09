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

    
    class func getMessagesFromAPI(fromAppDelegate: Bool,fromList: Bool, moc: NSManagedObjectContext, from: String!, completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
        
        let privateContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        privateContext.parentContext = moc
        
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
                    "limit" : "450"
                ]
            } else {
                params = [
                    "method" : "getSMS",
                    "limit" : "1"
                ]
            }
        }
        
        privateContext.performBlock { () -> Void in
            var coreMessages = CoreMessage.getMessages(moc, ascending: true).map({$0.id})
                        
            VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
                println(error)
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
                    }
                    let did = t["did"].stringValue
                    
                    if CoreMessage.isExistingMessageById(moc, id: id) == false /**&& CoreDeleteMessage.isDeletedMessage(moc, id: id) == false**/  {
                        if let currentUser = CoreUser.currentUser(privateContext) {
                            if type == true {
                                if currentUser.initialLogon == 1 || currentUser.initialLogon.boolValue == true  {
                                    flagValue = message_status.READ.rawValue
                                } else if fromList {
                                    flagValue = message_status.DELIVERED.rawValue
                                } else {
                                    flagValue = message_status.READ.rawValue
                                }
                            }
                        }
                        
                        
                        CoreMessage.createInManagedObjectContext(privateContext, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (t, error) -> () in
                        })
                    }
                }
                return completionHandler(responseObject: json, error: nil)
            }
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
        
//        let privateMoc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
//        privateMoc.parentContext = moc
        
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
                    "limit" : "30"
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
        
//        privateMoc.performBlock { () -> Void in
            VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
                
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
                        })
                    }
                }
                return completionHandler(responseObject: json, error: nil)
            }
//        }
    }
    
    class func sendMessageAPI(contact: String, messageText: String, did: String,
        completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
            let params = [
                "method":"sendSMS",
                "did":did,
                "dst":contact,
                "message": messageText
            ]
            
        VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
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
        VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
                if responseObject {
                   println(responseObject)
                }
                if error != nil {
                    println(error)
                }
            }
        }
        return completionHandler(responseObject: true, error: nil)
    }
}