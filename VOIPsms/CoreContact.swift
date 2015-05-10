//
//  CoreContact.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

class CoreContact: NSManagedObject {

    @NSManaged var contactId: String
    @NSManaged var messages: NSSet
    @NSManaged var lastModified: String
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?) -> Bool {
        
        let contact : CoreContact = NSEntityDescription.insertNewObjectForEntityForName("CoreContact", inManagedObjectContext: managedObjectContext) as! CoreContact
        contact.contactId = contactId
        if let lastModified = lastModified {
            contact.lastModified = lastModified
        } else {
            var formatter: NSDateFormatter = NSDateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            let stringDate: String = formatter.stringFromDate(NSDate())
            contact.lastModified = stringDate
        }
        
        if managedObjectContext.save(nil) {
            return true
        }
        return false
    }
    
    class func updateInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?) -> Bool {
        if let contact : CoreContact = CoreContact.currentContact(managedObjectContext, contactId: contactId) {
            
            if let lastModified = lastModified {
                contact.lastModified = lastModified
            } else {
                var formatter: NSDateFormatter = NSDateFormatter()
                formatter.dateFormat = "dd-MM-yyyy"
                let stringDate: String = formatter.stringFromDate(NSDate())
                contact.lastModified = stringDate
            }
            managedObjectContext.save(nil)
            return true
        }
        return false
    }
    
    class func currentContact(managedObjectContext: NSManagedObjectContext, contactId: String) -> CoreContact? {
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        let predicate = NSPredicate(format: "contactId == %@", contactId)
        fetchRequest.predicate = predicate
        var coreContact = [CoreContact]()
        var error : NSError? = nil
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [CoreContact] {
            coreContact = fetchResults
            if fetchResults.count > 0 {
                return coreContact[0]
            }
        } else {
            println("\(error?.userInfo)")
        }
        return nil
    }
    
    class func getContacts(moc: NSManagedObjectContext, did: String?, completionHandler: (responseObject: [CoreContact], error: NSError?) -> ()) {
        //perform fetch for all messages with did == did, get contact id from there
        //for each contact_id in DID append coreContacts array (if contactId doesnt exist yet in array)
        var coreContacts = [CoreContact]()
        
        if let did = did {

            let messages = CoreMessage.getMessagesByDID(moc, did: did)
            for m in messages {
                if let contact = CoreContact.currentContact(moc, contactId: m.contactId) {
                    if !contains(coreContacts, contact) {
                        coreContacts.append(contact)
                    }
                }
            }
        } else {
            let fetchRequest = NSFetchRequest(entityName: "CoreContact")
            let entity = NSEntityDescription.entityForName("CoreContact", inManagedObjectContext: moc)
            fetchRequest.entity = entity
            let sortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            fetchRequest.returnsObjectsAsFaults = false
            let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreContact]
            if fetchResults?.count > 0 {
                coreContacts = fetchResults!
            }
        }
        return completionHandler(responseObject: coreContacts, error: nil)
    }
    
    
    class func getMsgsByContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String) -> [CoreMessage] {
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let secondPredicate = NSPredicate(format: "did == %@", did)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        var coreMessages = [CoreMessage]()
        let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        
        return coreMessages
        
    }
    
    class func getIncomingMsgsByContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String) -> [CoreMessage] {
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let secondPredicate = NSPredicate(format: "type == %@", "1")
        let thirdPredicate = NSPredicate(format: "did == %@", did)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate, thirdPredicate])
        
        // Set the predicate on the fetch request
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        var coreMessages = [CoreMessage]()
        let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        
        return coreMessages
        
    }
    
    class func updateMessagesToRead(moc: NSManagedObjectContext, contactId:String, did: String) {
        
        let coreMessages = CoreContact.getMsgsByContact(moc, contactId: contactId, did: did)
            for cm in coreMessages {
                if cm.type == 1 || cm.type == true {
                    cm.flag = message_status.READ.rawValue
                    moc.save(nil)
                }
            }
    }
    
    
    class func isExistingContact(managedObjectContext: NSManagedObjectContext, contactId: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        fetchRequest.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "contactId == %@", contactId)
        fetchRequest.predicate = predicate
        
        let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [CoreContact]
        if fetchResults?.count > 0 {
            return true
        }
        
        return false
    }
    
    class func getLastMessageFromContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String) -> CoreMessage? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let secondPredicate = NSPredicate(format: "did == %@", did)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        
        var coreMessages = [CoreMessage]()
        var error : NSError? = nil
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [CoreMessage] {
            coreMessages = fetchResults
            if fetchResults.count > 0 {
                return coreMessages[0]
            }
        } else {
            println("\(error?.userInfo)")
        }
        return nil
        
    }
    
   

}
