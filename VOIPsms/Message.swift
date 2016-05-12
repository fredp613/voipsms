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
        
//        let privateContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
//        privateContext.parentContext = moc
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        //from should be last date in core data
        
        var fromStr : NSDate
        if from != nil {
            fromStr = dateFormatter.dateFromString(from)!
        } else {
            print("asfasfsdf \(CoreDID.getSelectedDID(moc)!)")
            if let selecteDID = CoreDID.getSelectedDID(moc) {
                if let unwrappedFromStr = dateFormatter.dateFromString(selecteDID.registeredOn) {
                    print("asdfasdfajsdflksdfja;slfjaslkf hihihi \(unwrappedFromStr)")
                    fromStr = unwrappedFromStr
                } else {
                    fromStr = NSDate()
                }
            } else {
                fromStr = NSDate()
            }
            
        }
        var params = [String : String]()

        if let currentUser = CoreUser.currentUser(moc) {

            
//            let calendar: NSCalendar = NSCalendar.currentCalendar()
            
            
            let date1 : NSDate = dateFormatter.dateFromString("2016-03-11")!
            
            let date2  = NSDate()
            
//           let interval = date2.timeIntervalSinceDate(fromStr)
            let numberOfDaysBetweenTodayAndRegistrationDate = fromStr.numberOfDaysUntilDateTime(date2)
            if numberOfDaysBetweenTodayAndRegistrationDate > 90 {
                let newDate = NSDate().dateByAddingTimeInterval(-80*24*60*60)
                fromStr = newDate
            }
            
            
                        
           
           
            if (currentUser.initialLogon.boolValue == true) || (currentUser.initialLoad.boolValue == true) {
                params = [
                    "method" : "getSMS",
                    "from" : dateFormatter.stringFromDate(fromStr),
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
        
        
//        privateContext.performBlock { () -> Void in
//            _ = CoreMessage.getMessages(moc, ascending: true).map({$0.id})
            
            VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls(moc1: moc).get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
                
                let json = responseObject
                for (_, t): (String, JSON) in json["sms"] {
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
                        
                        if let currentUser = CoreUser.currentUser(moc) {
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
                        
                        
                        CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: type, date: date, message: message, did: did, flag: flagValue, completionHandler: { (t, error) -> () in
                        })
                    }
                }
                return completionHandler(responseObject: json, error: nil)
            }
//        }
        
        
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
        let boldText  = contactStr
        let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(15)]
        let localNotification = UILocalNotification()
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
            VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls(moc1: moc).get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
                
                let json = responseObject
                for (key, t): (String, JSON) in json["sms"] {
                    
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
    
    class func sendMessageAPI(moc: NSManagedObjectContext, contact: String, messageText: String, did: String,
        completionHandler: (responseObject: JSON, error: NSError?) -> ()) {
            let params = [
                "method":"sendSMS",
                "did":did,
                "dst":contact,
                "message": messageText
            ]
            
        VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls(moc1: moc).get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in

                if error != nil {
                    return completionHandler(responseObject: responseObject, error: error)
                } else {
                    return completionHandler(responseObject: responseObject, error: nil)
                }
            }
    }
    
    class func deleteMessagesFromAPI(moc: NSManagedObjectContext, ids: [String]!, completionHandler: (responseObject: Bool, error: NSError?)->()) {
        
        for id in ids {
            let params = [
                "method":"deleteSMS",
                "id":id
            ]
        VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls(moc1: moc).get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
//                if responseObject {
//                   print(responseObject)
//                }
//                if error != nil {
//                    print(error)
//                }
            }
        }
        return completionHandler(responseObject: true, error: nil)
    }
}