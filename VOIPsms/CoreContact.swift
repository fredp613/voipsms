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
    @NSManaged var lastModified: NSDate
    @NSManaged var addressBookSyncLastModified: NSDate!
    @NSManaged var fullName: String!
    @NSManaged var phoneLabel: String!
    var ccs = [CoreContact]()
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?) -> CoreContact? {
        let contact : CoreContact = NSEntityDescription.insertNewObjectForEntityForName("CoreContact", inManagedObjectContext: managedObjectContext) as! CoreContact
        contact.contactId = contactId
        if let lastModified = lastModified {

            var formatter1: NSDateFormatter = NSDateFormatter()
            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let parsedDate: NSDate = formatter1.dateFromString(lastModified)!
            contact.lastModified = parsedDate
        } else {
            contact.lastModified = NSDate()
        }
        let error : NSError? = nil
        if managedObjectContext.save(nil) {
            println("contact saved")
            return contact
        }

        return nil
    }
    
    class func updateInManagedObjectContext(managedObjectContext: NSManagedObjectContext, contactId: String, lastModified: String?, fullName: String?, phoneLabel: String?, addressBookLastModified: NSDate?) -> Bool {
        if let contact : CoreContact = CoreContact.currentContact(managedObjectContext, contactId: contactId) {
            
            if let lastModified = lastModified {
                
                if let cc = CoreContact.getLastMessageFromContact(managedObjectContext, contactId: contactId, did: CoreDID.getSelectedDID(managedObjectContext)!.did) {
                    var formatter1: NSDateFormatter = NSDateFormatter()
                    formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    let parsedDate: NSDate = formatter1.dateFromString(cc.date)!
                    contact.lastModified = parsedDate
                }
            } else {
                if fullName == nil {
                    contact.lastModified = NSDate()
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
            managedObjectContext.save(nil)
            return true
        }
        return false
    }
    
    class func updateContactInMOC(moc: NSManagedObjectContext) {
        moc.save(nil)
    }
    
    class func getAllContacts(managedObjectContext: NSManagedObjectContext) -> [CoreContact]? {
        let fetchRequest = NSFetchRequest(entityName: "CoreContact")
        var coreContacts = [CoreContact]()
        var error : NSError? = nil
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [CoreContact] {
            coreContacts = fetchResults
            if fetchResults.count > 0 {
                return coreContacts
            }
        } else {
            println("\(error?.userInfo)")
        }
        
        return nil
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
                            if !contains(coreContacts, contact) {
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
                            if !contains(coreContacts, contact) {
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
                                        if !contains(coreContacts, contact1) {
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
                        if !contains(coreContacts, contact) {
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
            let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreContact]
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
                                if !contains(existingContacts, contact1) {
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
        
        var coreContacts = existingContacts
        var contactResult = [ContactStruct]()
        
        for c in coreContacts {
            var contact = ContactStruct()
            contact.contactId = c.contactId
            if c.phoneLabel != nil {
                 contact.phoneLabel = c.phoneLabel
            }
            contactResult.append(contact)
        }
        
        Contact().loadAddressBook { (responseObject, error) -> () in
            var contacts = responseObject
            for c in contacts {
                if (c.contactFullName.lowercaseString.rangeOfString(searchTerm.lowercaseString) != nil) || (c.recordId.rangeOfString(searchTerm.lowercaseString) != nil) {
                    var contactStruct = ContactStruct()
                    contactStruct.contactId = c.recordId
                    contactStruct.contactName = c.contactFullName
                    contactStruct.phoneLabel = c.phoneLabel
                    if !contains(contactResult.map({$0.contactId}), c.recordId) {
                        contactResult.append(contactStruct)
                    }
                }
            }
            return completionHandler(contactResult)
        }
        
//        Contact().getContactsDict({ (contacts) -> () in
//            if contacts.count > 0 {
//                for (key,value) in contacts {
//                    let numberStr = String(key)
//                    if (value.lowercaseString.rangeOfString(searchTerm.lowercaseString) != nil) || (numberStr.rangeOfString(searchTerm.lowercaseString) != nil) {
//                        var contactStruct = ContactStruct()
//                        contactStruct.contactId = key
//                        contactStruct.contactName = value
//                        if !contains(contactResult.map({$0.contactId}), key) {
//                            contactResult.append(contactStruct)
//                        }
//                    }
//                }
//                return completionHandler(contactResult)
//            }
//        })
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
                if cm.type == 1 || cm.type.boolValue == true {
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
    
    class func getLastMessageFromContact(managedObjectContext: NSManagedObjectContext, contactId: String, did: String?) -> CoreMessage? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreMessage")
        fetchRequest.returnsObjectsAsFaults = false
        let firstPredicate = NSPredicate(format: "contactId == %@", contactId)
        
        if let did = did {
            var secondPredicate = NSPredicate(format: "did == %@", did)
            let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [firstPredicate, secondPredicate])
            fetchRequest.predicate = predicate
        } else {
            fetchRequest.predicate = firstPredicate
        }
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
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
