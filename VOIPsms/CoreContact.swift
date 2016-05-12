//
//  CoreContact.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData



struct ContactStruct {
    var contactName = String()
    var contactId = String()
    var recordId = String()
    var phoneLabel = String()
    var lastMsgDate = String()
    var lastMsg = String()
    var lastMsgType = NSNumber()
    var lastMsgFlag = String()
    var did = String()
}

class CoreContact: NSManagedObject {

    @NSManaged var contactId: String
    @NSManaged var messages: NSSet
    @NSManaged var lastModified: NSDate
    @NSManaged var addressBookSyncLastModified: NSDate!
    @NSManaged var fullName: String!
    @NSManaged var phoneLabel: String!
    @NSManaged var deletedContact: NSNumber!
    var ccs = [CoreContact]()
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?) -> CoreContact? {
        let contact : CoreContact = NSEntityDescription.insertNewObjectForEntityForName("CoreContact", inManagedObjectContext: managedObjectContext) as! CoreContact
        contact.contactId = contactId
        if let lastModified = lastModified {

            let formatter1: NSDateFormatter = NSDateFormatter()
            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let parsedDate: NSDate = formatter1.dateFromString(lastModified)!
            contact.lastModified = parsedDate
        } else {
            contact.lastModified = NSDate().dateByAddingTimeInterval(NSTimeIntervalSince1970)
        }
//        if managedObjectContext.save(nil) {
//            println("contact saved")
//            return contact
//        }
//        CoreDataStack().saveContext(managedObjectContext)
        do {
            try managedObjectContext.save()
        } catch _ {
            print("somethign wrong")
        }

        return contact

//        return nil
    }
    
    class func updateInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?, fullName: String?, phoneLabel: String?, addressBookLastModified: NSDate?) -> Bool {
        if let contact : CoreContact = CoreContact.currentContact(managedObjectContext, contactId: contactId) {
            
            if let _ = lastModified {
                
                if let cc = CoreContact.getLastMessageFromContact(managedObjectContext, contactId: contactId, did: CoreDID.getSelectedDID(managedObjectContext)!.did) {
                    let formatter1: NSDateFormatter = NSDateFormatter()
                    formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    let parsedDate: NSDate = formatter1.dateFromString(cc.date)!
                    contact.lastModified = parsedDate
                } else {
                    contact.lastModified = NSDate().dateByAddingTimeInterval(NSTimeIntervalSince1970)
                }

            } else {
                
                if fullName == nil {
                    contact.lastModified = NSDate().dateByAddingTimeInterval(NSTimeIntervalSince1970)
                }
                
            }
            if let fullName = fullName {
                contact.fullName = fullName
            }
            if let phoneLabel = phoneLabel {
                contact.phoneLabel = phoneLabel
            }
            if let sync = addressBookLastModified {
                contact.addressBookSyncLastModified = sync
            }
//            managedObjectContext.save(nil)
        
            do {
                try managedObjectContext.save()
                return true
            } catch _ {
                print("something went wrong")
            }
        }
        return false
    }
    
    class func updateContactInMOC(moc: NSManagedObjectContext) {
//        moc.save(nil)
        do {
            try moc.save()
        } catch _ {
            print("somethign wrong")
        }

    }
    
    class func getAllContacts1(managedObjectContext: NSManagedObjectContext) throws -> [CoreContact]? {

        var coreContacts = [CoreContact]()
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        
        let entity = NSEntityDescription.entityForName("CoreContact", inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        print("get all contacts")
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as! [CoreContact]

            coreContacts = fetchResults
            if fetchResults.count > 0 {
                return coreContacts
            }
        }
        catch let error {
            print(error)
            return nil
        }
        return nil
    }
    class func getAllContacts(managedObjectContext: NSManagedObjectContext) -> [CoreContact]? {
        
        var coreContacts = [CoreContact]()
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        
        let entity = NSEntityDescription.entityForName("CoreContact", inManagedObjectContext: managedObjectContext)
        fetchRequest.entity = entity
        print("get all contacts")
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as! [CoreContact]
            
            coreContacts = fetchResults
            if fetchResults.count > 0 {
                return coreContacts
            }
        }
        catch let error {
            print(error)
            return nil
        }
        return nil
    }
    
    class func currentContact(managedObjectContext: NSManagedObjectContext, contactId: String) -> CoreContact? {
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        let predicate = NSPredicate(format: "contactId == %@", contactId)
        fetchRequest.predicate = predicate
        var coreContact = [CoreContact]()
//        let error : NSError? = nil
        
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as! [CoreContact]
            coreContact = fetchResults
            if fetchResults.count > 0 {
                return coreContact[0]
            }
        }
        catch {
            print(error)
            return nil
        }
        

        return nil
    }
    

    
    class func getContacts(moc: NSManagedObjectContext, did: String?, dst: String?, name: String?, message: String?, completionHandler: (responseObject: NSArray, error: NSError?) -> ()) {
        //perform fetch for all messages with did == did, get contact id from there
        //for each contact_id in DID append coreContacts array (if contactId doesnt exist yet in array)
        var coreContacts = [CoreContact]()
        
        
        if let did = did  {
            let messagesByDid = CoreMessage.getMessagesByDID(moc, did: did)
            
            if let dst = dst {
                if let messagesByDst = CoreMessage.getMessagesByDST(moc, dst: dst, did: did) {
                    for m in messagesByDst {
                        if let contact = CoreContact.currentContact(moc, contactId: m.contactId) {
                            if !coreContacts.contains(contact) {
                                coreContacts.append(contact)
                            }
                        }
                    }
                }
            }
            
            if let message = message {
                if let messagesByString = CoreMessage.getMessagesByString(moc, message: message, did: did) {
                    for m in messagesByString {
                        if let contact = CoreContact.currentContact(moc, contactId: m.contactId) {
                            if !coreContacts.contains(contact) {
                                coreContacts.append(contact)
                            }
                        }
                    }
                }
            }
            
            if let name = name {
                if Contact().checkAccess() {
                    Contact().getContactsDict({ (contacts) -> () in
                        var closureContacts : [CoreContact] = coreContacts
                        if contacts.count > 0 {
                            for (key,value) in contacts {
                                if (value.rangeOfString(name) != nil) {
                                    if let contact1 = CoreContact.currentContact(moc, contactId: key) {
                                        if !coreContacts.contains(contact1) {
                                            coreContacts.append(contact1)
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
            }
            
            if (dst == nil && name == nil && message == nil) || (dst == "" && name == "" && message == "")  {
                for m in messagesByDid {
                    // do some if msg id not already in
                    if let contact = CoreContact.currentContact(moc, contactId: m.contactId) {
                        if !coreContacts.contains(contact) {
                            coreContacts.append(contact)
                        }
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
            let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreContact]
            if fetchResults?.count > 0 {
                coreContacts = fetchResults!
            }
        }
        
        let sortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        let ns = NSArray(array: coreContacts).sortedArrayUsingDescriptors([sortDescriptor])
        
        return completionHandler(responseObject: ns, error: nil)
    }
    
    class func findByName(moc: NSManagedObjectContext, searchTerm: String, existingContacts: [CoreContact], completionHandler: ([CoreContact]?)->()) {
        var coreContacts : [CoreContact] = existingContacts
            Contact().getContactsDict({ (contacts) -> () in
                if contacts.count > 0 {
                    for (key,value) in contacts {
                        if (value.lowercaseString.rangeOfString(searchTerm.lowercaseString) != nil) {
                            if let contact1 = CoreContact.currentContact(moc, contactId: key) {
                                if !existingContacts.contains(contact1) {
                                    coreContacts.append(contact1)
                                }
                            }
                        }
                    }
                    return completionHandler(coreContacts)
                }
            })
    }
    
    class func findAllContactsByName(moc: NSManagedObjectContext, searchTerm: String, existingContacts: [CoreContact], completionHandler: ([ContactStruct]?)->()) {
        
        let coreContacts = existingContacts
        var contactResult = [ContactStruct]()
        
        for c in coreContacts {
            var contact = ContactStruct()
            contact.contactId = c.contactId
            if c.phoneLabel != nil {
                 contact.phoneLabel = c.phoneLabel
            }
            contactResult.append(contact)
        }
        if Contact().checkAccess() {
            
            let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            privateMOC.parentContext = moc
            
            Contact().loadAddressBook(privateMOC, completionHandler: { (responseObject, error) in
                let contacts = responseObject
                for c in contacts {
                    if (c.contactFullName.lowercaseString.rangeOfString(searchTerm.lowercaseString) != nil) || (c.recordId.rangeOfString(searchTerm.lowercaseString) != nil) {
                        var contactStruct = ContactStruct()
                        contactStruct.contactId = c.recordId
                        contactStruct.contactName = c.contactFullName
                        contactStruct.phoneLabel = c.phoneLabel
                        if !contactResult.map({$0.contactId}).contains(c.recordId) {
                            contactResult.append(contactStruct)
                        }
                    }
                }
                return completionHandler(contactResult)
            })
        } else {
            return completionHandler(contactResult)
        }
        
    }
    
    
    
    
    class func getMsgsByContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String) -> [CoreMessage] {
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let secondPredicate = NSPredicate(format: "did == %@", did)
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        var coreMessages = [CoreMessage]()
        let fetchResults = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [CoreMessage]
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
        let fetchResults = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [CoreMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
        }
        
        return coreMessages
        
    }
    
    class func updateMessagesToRead(moc: NSManagedObjectContext, contactId:String, did: String) {
        
        let coreMessages = CoreContact.getMsgsByContact(moc, contactId: contactId, did: did)
            for cm in coreMessages {
                if cm.type == 1 || cm.type.boolValue == true {
                    cm.flag = message_status.READ.rawValue
                    do {
                        try moc.save()
                    } catch _ {
                    }
                }
            }
    }
    

    
    
    class func isExistingContact(managedObjectContext: NSManagedObjectContext, contactId: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        fetchRequest.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "contactId == %@", contactId)
        fetchRequest.predicate = predicate
        
        let fetchResults = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [CoreContact]
        if fetchResults?.count > 0 {
            return true
        }
        
        return false
    }
    
    class func getLastIncomingMessageFromContact(moc: NSManagedObjectContext, contactId: String, did: String) -> CoreMessage? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let secondPredicate = NSPredicate(format: "did == %@", did)
//        let thirdPredicate = NSPredicate(format: "id != %@", "")
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        
        var coreMessages = [CoreMessage]()
//        let error : NSError? = nil
        
        do {
            let fetchResults = try moc.executeFetchRequest(fetchRequest) as! [CoreMessage]
            coreMessages = fetchResults
            if fetchResults.count > 0 {
                return coreMessages[0]
            }
        }
        catch {
            print(error)
            return nil
        }
        
        return nil
    }
    
    class func getLastMessageFromContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String?) -> CoreMessage? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let sortDescriptor = NSSortDescriptor(key: "dateForSort", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        let validMessagePredicate = NSPredicate(format: "flag != %@ ", message_status.UNDELIVERED.rawValue)
            if let did = did {
                let secondPredicate = NSPredicate(format: "did == %@", did)
                let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate /**, validMessagePredicate**/])
                fetchRequest.predicate = predicate
            } else {
                let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, validMessagePredicate])
                fetchRequest.predicate = predicate
            }
//        }
        fetchRequest.fetchLimit = 1
        
        var coreMessages = [CoreMessage]()
//        let error : NSError? = nil
        
        do {
            let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as! [CoreMessage]
            coreMessages = fetchResults
            if fetchResults.count > 0 {
                return coreMessages[0]
            }
        }
        catch {
            print(error)
            return nil
        }

        return nil
        
    }
    
   

}
