//
//  Contact.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Contact {
    
    var addressBook = APAddressBook()
    var access = APAddressBook.access()
    var searchTerm = String()
    var coreContacts = [CoreContact]()
    var addressBook1: ABAddressBookRef?

    init() {
        self.addressBook = APAddressBook()
        self.access = APAddressBook.access()      
    }

    
    func checkAccess() -> Bool {
        
        switch(access)
        {
        case APAddressBookAccess.Unknown:
            return false
        case APAddressBookAccess.Granted:
            return true
        case APAddressBookAccess.Denied:
            return false
        }
    }
    
    
    func createContact(phone: String, firstName: String, lastName: String) -> Bool {
        var error: Unmanaged<CFErrorRef>? = nil
        
        var adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
        var newContact:ABRecordRef! = ABPersonCreate().takeRetainedValue()
        var success:Bool = false


        success = ABRecordSetValue(newContact, kABPersonFirstNameProperty, firstName, &error)
        success = ABRecordSetValue(newContact, kABPersonLastNameProperty, lastName, &error)
        let propertyType: NSNumber = kABMultiStringPropertyType
        var phoneNumbers: ABMutableMultiValueRef =  createMultiStringRef()
        ABMultiValueAddValueAndLabel(phoneNumbers, phone, kABPersonPhoneMainLabel, nil)
        success = ABRecordSetValue(newContact, kABPersonPhoneProperty, phoneNumbers, &error)

        success = ABAddressBookAddRecord(adbk, newContact, &error)
        success = ABAddressBookSave(adbk, &error)

        if success {
            return true
        }
        return false
    }
    
    
    func createMultiStringRef() -> ABMutableMultiValueRef {
        let propertyType: NSNumber = kABMultiStringPropertyType
        return Unmanaged.fromOpaque(ABMultiValueCreateMutable(propertyType.unsignedIntValue).toOpaque()).takeUnretainedValue() as NSObject as ABMultiValueRef
    }
  
    
    func getContactsDict(completionHandler: ([String: String]) -> ()){
        var contactsDict = [String: String]()
        self.addressBook.loadContacts(
            { (contacts: [AnyObject]!, error: NSError!) in
                if (contacts != nil) {
                    for c in contacts {
                        for p in c.phones! {
                            let regex = NSRegularExpression(pattern: "[0-9]",
                                options: nil, error: nil)!
                            let pStr = p as! NSString
                            let results = regex.matchesInString(p as! String,
                                options: nil, range: NSMakeRange(0, pStr.length))
                            let mappedResults = map(results) { pStr.substringWithRange($0.range)}
                            let strRepresentationResults = "".join(mappedResults)
                            contactsDict.updateValue("\(c.firstName) \(c.lastName)", forKey: strRepresentationResults)
                        }
                    }
                    return completionHandler(contactsDict)
                }
        })
    }
    
    func getContactsByName(searchTerm: String, moc: NSManagedObjectContext, completionHandler: ([CoreContact]?) -> ()) -> [CoreContact]? {
        var contactsDict = [String: String]()
        self.searchTerm = searchTerm
        self.addressBook.loadContacts(
            { (contacts: [AnyObject]!, error: NSError!) in
                
                if (contacts != nil) {
                    for c in contacts {
                        for p in c.phones! {
                            let regex = NSRegularExpression(pattern: "[0-9]",
                                options: nil, error: nil)!
                            let pStr = p as! NSString
                            let results = regex.matchesInString(p as! String,
                                options: nil, range: NSMakeRange(0, pStr.length))
                            let mappedResults = map(results) { pStr.substringWithRange($0.range)}
                            let strRepresentationResults = "".join(mappedResults)
                            contactsDict.updateValue("\(c.firstName) \(c.lastName)", forKey: strRepresentationResults)
                        }
                    }
                    for (key, value) in contactsDict {
                        if (value.rangeOfString(self.searchTerm) != nil) {
                            println(searchTerm)
                            if let contact1 = CoreContact.currentContact(moc, contactId: key) {
                                if !contains(self.coreContacts, contact1) {
                                    println("hi")
                                    self.coreContacts.append(contact1)
                                }
                            }
                        }
                    }
                    return completionHandler(self.coreContacts)
                }
        })
        println(self.coreContacts)
        
        if self.coreContacts.count > 0 {
            for c in self.coreContacts {
                println(c.contactId)
            }
            return self.coreContacts
        }
        
        return nil
        
    }
    
    
//    if let name = name {
//        Contact().getContactsDict({ (contacts) -> () in
//            var closureContacts : [CoreContact] = coreContacts
//            if contacts.count > 0 {
//                for (key,value) in contacts {
//                    if (value.rangeOfString(name) != nil) {
//                        if let contact1 = CoreContact.currentContact(moc, contactId: key) {
//                            if !contains(coreContacts, contact1) {
//                                coreContacts.append(contact1)
//                            }
//                        }
//                    }
//                }
//            }
//        })
//    }
    
   
    

}

