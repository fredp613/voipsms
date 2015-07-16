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
    case UNDELIVERED = "undelivered"
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
        
        if let c = CoreContact.currentContact(managedObjectContext, contactId: contact) {
//            if  CoreContact.updateInManagedObjectContext(managedObjectContext, contactId: contact, lastModified: date, fullName: nil, phoneLabel: nil, addressBookLastModified: nil) {
//                coreMessage.contact = c
//            }
            var formatter1: NSDateFormatter = NSDateFormatter()
            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let parsedDate: NSDate = formatter1.dateFromString(date)!
            c.lastModified = parsedDate
            CoreContact.updateContactInMOC(managedObjectContext)
            
        } else {
            if let c = CoreContact.createInManagedObjectContext(managedObjectContext, contactId: contact, lastModified: date) {
                coreMessage.contact = c
            }
        }
        let err = NSError()
                
        CoreDataStack().saveContext(managedObjectContext)
//        if managedObjectContext.save(nil) {            
            return completionHandler(responseObject: coreMessage, error: nil)
//        } else {
//            return completionHandler(responseObject: nil, error: err)
//        }
    }
    
    class func updateInManagedObjectContext(moc: NSManagedObjectContext, coreMessage: CoreMessage) {
        CoreDataStack().saveContext(moc)
        
//        if moc.save(nil) {
//        }
    }
    
    class func deleteMessage(moc: NSManagedObjectContext, coreMessage: CoreMessage) {
        if coreMessage.id != "" {
//            println(coreMessage.id)
            CoreDeleteMessage.createInManagedObjectContext(moc, id: coreMessage.id)
//            Message.deleteMessagesFromAPI([coreMessage.id], completionHandler: { (responseObject, error) -> () in
//            })
        }
        var contact = coreMessage.contactId
        var did = coreMessage.did
        
        moc.deleteObject(coreMessage)
        moc.save(nil)
        
        if let lastMessage = CoreContact.getLastMessageFromContact(moc, contactId: contact, did: did) {
            var currentContact = CoreContact.currentContact(moc, contactId: contact)
            var formatter1: NSDateFormatter = NSDateFormatter()
            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
            currentContact?.lastModified = parsedDate
            CoreContact.updateContactInMOC(moc)
        }
        
        
      
        
    }
    
    class func deleteAllMessagesFromContact(moc: NSManagedObjectContext, contactId: String!, did: String, completionHandler: (responseObject: Bool, error: NSError?)->()) {
        
        let coreMessages = CoreContact.getMsgsByContact(moc, contactId: contactId, did: did)
        
        for cm in coreMessages {
            CoreMessage.deleteMessage(moc, coreMessage: cm)
        }
        
        return completionHandler(responseObject: true, error: nil)
        
    }
    
    class func deleteInManagedObjectContext(moc: NSManagedObjectContext, id: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        let predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        for cm in coreMessages {
            CoreDeleteMessage.createInManagedObjectContext(moc, id: cm.id)
            moc.deleteObject(cm)
            moc.save(nil)
            return true
        }
        
        return false
    }
    
    class func deleteStaleMsgInManagedObjectContext(moc: NSManagedObjectContext, coreId: NSNumber) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        let predicate = NSPredicate(format: "coreId == %@", coreId)
        fetchRequest.predicate = predicate
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        for cm in coreMessages {
            moc.deleteObject(cm)
            moc.save(nil)
            return true
        }
        
        return false
    }

    class func isExistingMessageById(moc: NSManagedObjectContext, id: String) -> Bool {
        if let messageExists = CoreMessage.getMessageById(moc, Id: id) {
            return true
        }
        return false
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
            CoreContact.updateInManagedObjectContext(moc, contactId: cm.contactId, lastModified: stringDate,fullName: nil, phoneLabel: nil, addressBookLastModified: nil)
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
    
    class func getMessageById(moc: NSManagedObjectContext, Id: String) -> CoreMessage? {
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let predicate = NSPredicate(format: "id == %@", Id)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
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
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
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
    
    class func getMessagesByDST(moc: NSManagedObjectContext, dst: String, did: String?) -> [CoreMessage]? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        if let did = did {
            let firstPredicate = NSPredicate(format: "contactId CONTAINS[cd] %@", dst)
            let secondPredicate = NSPredicate(format: "did == %@", did)
            let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
            fetchRequest.predicate = predicate
        } else {
            let predicate = NSPredicate(format: "contactId CONTAINS[cd] %@", dst)
            fetchRequest.predicate = predicate
        }
        
        
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
            return coreMessages
        }
        return nil
    }
    
    class func getMessagesByString(moc: NSManagedObjectContext, message: String, did: String) -> [CoreMessage]? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let entity = NSEntityDescription.entityForName("CoreMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        let firstPredicate = NSPredicate(format: "message CONTAINS[cd] %@", message)
        let secondPredicate = NSPredicate(format: "did == %@", did)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        fetchRequest.predicate = predicate
        
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreMessage]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
            return coreMessages
        }
        return nil
    }
    
    class func getLastMsgByDID(moc: NSManagedObjectContext, did: String) -> CoreMessage? {
        
            let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
            fetchRequest.returnsObjectsAsFaults = false
            let firstPredicate = NSPredicate(format: "did == %@", did)
            let secondPredicate = NSPredicate(format: "id != %@", "")
            let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
            fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.fetchLimit = 1
            
            var coreMessages = [CoreMessage]()
            var error : NSError? = nil
            if let fetchResults = moc.executeFetchRequest(fetchRequest, error: &error) as? [CoreMessage] {
                coreMessages = fetchResults
                if fetchResults.count > 0 {
                    return coreMessages[0]
                }
            } else {
                println("\(error?.userInfo)")
            }
            return nil

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
