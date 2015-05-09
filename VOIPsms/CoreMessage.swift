//
//  CoreMessage.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-16.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

enum message_status : String {
    case PENDING = "pending"
    case DELIVERED = "delivered"
    case READ = "read"
}

class CoreMessage: NSManagedObject {

    @NSManaged var contactId: String
    @NSManaged var did: String
    @NSManaged var message: String
    @NSManaged var type: NSNumber
    @NSManaged var id: String
    @NSManaged var coreId: NSNumber
    @NSManaged var date: String
    @NSManaged var flag: String
    @NSManaged var contact: CoreContact
    
//    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contact: String, id: String, type: Bool, date: String, message: String, did: String, flag: String) -> CoreMessage? {
//        
//        let coreMessage : CoreMessage = NSEntityDescription.insertNewObjectForEntityForName("CoreMessage", inManagedObjectContext: managedObjectContext) as! CoreMessage
//        coreMessage.message = message
//        coreMessage.contactId = contact
//        coreMessage.id = id
//        coreMessage.type = type
//        coreMessage.date = date
//        coreMessage.did = did
//        coreMessage.flag = flag
//        
//        var uuid = NSNumber()
//        if CoreMessage.getMessages(managedObjectContext, ascending: false).count > 0 {
//            let lastMsgId = CoreMessage.getMessages(managedObjectContext, ascending: false)[0].coreId
//            var newMsgID = lastMsgId.intValue + 1
//            coreMessage.coreId = NSNumber(int: newMsgID)
//            uuid = NSNumber(int: newMsgID)
//        } else {
//            coreMessage.coreId = 1
//        }
//        
//
//
//            if managedObjectContext.save(nil) {
//                return coreMessage
//            }
//
//        
//        return nil
//        
//        
//    }
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contact: String, id: String, type: Bool, date: String, message: String, did: String, flag: String,completionHandler: (responseObject: CoreMessage?, error: NSError?) -> ()) {

            let coreMessage : CoreMessage = NSEntityDescription.insertNewObjectForEntityForName("CoreMessage", inManagedObjectContext: managedObjectContext) as! CoreMessage
            coreMessage.message = message
            coreMessage.contactId = contact
            coreMessage.id = id
            coreMessage.type = type
            coreMessage.date = date
            coreMessage.did = did
            coreMessage.flag = flag
            
            var uuid = NSNumber()
            if CoreMessage.getMessages(managedObjectContext, ascending: false).count > 0 {
                let lastMsgId = CoreMessage.getMessages(managedObjectContext, ascending: false)[0].coreId
                var newMsgID = lastMsgId.intValue + 1
                coreMessage.coreId = NSNumber(int: newMsgID)
                uuid = NSNumber(int: newMsgID)
            } else {
                coreMessage.coreId = 1
            }
        
            let err = NSError()
            if managedObjectContext.save(nil) {
                return completionHandler(responseObject: coreMessage, error: nil)
            } else {
                return completionHandler(responseObject: nil, error: err)
            }
        
    }

    
    class func isExistingMessage(moc: NSManagedObjectContext, coreId: NSNumber) -> Bool {
        if let messageExists = CoreMessage.getMessageByUUID(moc, coreId: coreId) {
            return true
        }

        return false
    }
    
    class func updateSentMessageFromAPI(moc: NSManagedObjectContext, coreId:NSNumber, id: String) -> CoreMessage? {
        
        if let cm = CoreMessage.getMessageByUUID(moc, coreId: coreId) {
            cm.id = id
            moc.save(nil)
            
            var formatter: NSDateFormatter = NSDateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            let stringDate: String = formatter.stringFromDate(NSDate())
            CoreContact.updateInManagedObjectContext(moc, contactId: cm.contactId, lastModified: stringDate)
            return cm
        }
        return nil
    }
    
    class func getMessages(moc: NSManagedObjectContext, ascending: Bool) -> [CoreMessage] {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        let sortDescriptor = NSSortDescriptor(key: "coreId", ascending: ascending)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        return coreMessages
    }
    
    class func getMessageByUUID(moc: NSManagedObjectContext, coreId: NSNumber) -> CoreMessage? {
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let predicate = NSPredicate(format: "coreId == %@", coreId)
        fetchRequest.predicate = predicate
        var error : NSError? = nil
        if let fetchResults = moc.executeFetchRequest(fetchRequest, error: &error) as? [CoreMessage] {
            if fetchResults.count > 0 {
                return fetchResults[0] as CoreMessage
            }
        } else {
            println("\(error?.userInfo)")
        }
        return nil
    }
    
    class func getMessagesByDID(moc: NSManagedObjectContext, did: String) -> [CoreMessage] {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        let predicate = NSPredicate(format: "did == %@", did)
        fetchRequest.predicate = predicate
        
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        return coreMessages
    }
    
    class func sendMessage(moc: NSManagedObjectContext, contact: String, messageText: String, did: String, completionHandler: (responseObject: CoreMessage?, error: NSError?) -> ()) {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var dateStr = formatter.stringFromDate(date)
        
        CoreMessage.createInManagedObjectContext(moc, contact: contact, id: "", type: false, date: dateStr, message: messageText, did: did, flag: message_status.PENDING.rawValue) { (responseObject, error) -> () in
            let err = NSError()
            if responseObject != nil {
                return completionHandler(responseObject: responseObject, error: nil)
            } else {
                return completionHandler(responseObject: nil, error: err)
                
            }
        }

    }
    
    

    
}
