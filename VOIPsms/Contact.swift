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

class AddressBookContactStruct {
    var contactFullName : String = String()
    var recordId : String = String()
    var phoneLabel : String = String()
    init() {

    }
}

class Contact {
    
    var addressBook = APAddressBook()
    var access = APAddressBook.access()
    var searchTerm = String()
    var coreContacts = [CoreContact]()
    var addressBook1: ABAddressBookRef?
    var contactsArr : [AddressBookContactStruct] = [AddressBookContactStruct]()

    init() {
        self.addressBook = APAddressBook()
        self.access = APAddressBook.access()
    }

    
    func checkAccess() -> Bool {
        
        switch(access)
        {
        case APAddressBookAccess.Unknown:
            return true
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
    
    func addPhoneToExistingContact(recordId: String, phone: String) -> Bool {
//        var error: Unmanaged<CFErrorRef>? = nil
        var adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        let rid : ABRecordID = NSNumber(integer: recordId.toInt()!).intValue
        var existingContact : ABRecord = ABAddressBookGetPersonWithRecordID(adbk, rid).takeUnretainedValue()
        var success:Bool = false
        var phones: AnyObject = ABRecordCopyValue(existingContact, kABPersonPhoneProperty).takeRetainedValue()
        var phone1: ABMutableMultiValue = ABMultiValueCreateMutableCopy(phones).takeRetainedValue()
        ABMultiValueAddValueAndLabel(phone1, phone, kABPersonPhoneMobileLabel, nil)
        ABRecordSetValue(existingContact, kABPersonPhoneProperty, phone1,nil);
        ABAddressBookSave(adbk, nil)

        return true
    }
    
    
    func createMultiStringRef() -> ABMutableMultiValueRef {
        let propertyType: NSNumber = kABMultiStringPropertyType
        return Unmanaged.fromOpaque(ABMultiValueCreateMutable(propertyType.unsignedIntValue).toOpaque()).takeUnretainedValue() as NSObject as ABMultiValueRef
    }
    func getContactsDict(completionHandler: ([String : String]) -> ()){
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
                            contactsDict.updateValue("\(c.firstName) \(c.lastName)", forKey:strRepresentationResults)
                        }
                    }
                    return completionHandler(contactsDict)
                }
        })
    }
    func getAllContacts(keyword: String?) -> [AddressBookContactStruct] {

        
        
//        var tstStr = [NSString]()
        var adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        
        let people = ABAddressBookCopyArrayOfAllPeople(adbk).takeRetainedValue() as NSArray as [ABRecord]
//        let phones: ABMultiValueRef = ABRecordCopyValue(people, kABPersonPhoneProperty) as! ABMultiValueRef
        for person in people {
            
            if let fullName = ABRecordCopyCompositeName(person)?.takeRetainedValue() as? NSString {
                if let keyword = keyword {
                    

                    
                    
                    if fullName.lowercaseString.rangeOfString(keyword.lowercaseString) != nil {
                        var abContact = AddressBookContactStruct()
                        abContact.contactFullName = fullName as String
                        abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                        self.contactsArr.append(abContact)
                    } else {
                        var abContact = AddressBookContactStruct()
                        abContact.contactFullName = fullName as String
                        abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                        self.contactsArr.append(abContact)
                    }
                } else {
                    var abContact = AddressBookContactStruct()
                    abContact.contactFullName = fullName as String
                    abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                    self.contactsArr.append(abContact)
                }
            }
        }
        return self.contactsArr
    }
    
    func syncAddressBook1() {
        let moc: NSManagedObjectContext = CoreDataStack().managedObjectContext!
        if let coreContacts = CoreContact.getAllContacts(moc) {
            for cc in coreContacts {
                self.loadAddressBook { (responseObject, error) -> () in
                    let contacts = responseObject
                    let filteredArray = contacts.filter() {$0.recordId == cc.contactId}
                    if let fullName = filteredArray.map({$0.contactFullName}).last {
                        let phoneLabel = filteredArray.map({$0.phoneLabel}).last!
                        CoreContact.updateInManagedObjectContext(moc, contactId: cc.contactId, lastModified: nil, fullName: fullName, phoneLabel: phoneLabel, addressBookLastModified: NSDate())
                    }

                }
            }
        }
    }
    
    func loadAddressBook(completionHandler: (responseObject: [AddressBookContactStruct], error: NSError?) -> ()) {

        let moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        var adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        var cs : [String] = [String]()
        
        struct contactS {
            var phone : String
            var fullName : String
        }
        
        let people = ABAddressBookCopyArrayOfAllPeople(adbk).takeRetainedValue() as NSArray as [ABRecord]
        for person in people {
            var lastMod: NSDate = (ABRecordCopyValue(person, kABPersonModificationDateProperty).takeRetainedValue() as? NSDate)!
            var phones : ABMultiValueRef = ABRecordCopyValue(person, kABPersonPhoneProperty).takeRetainedValue() as ABMultiValueRef
            if let fullName = ABRecordCopyCompositeName(person)?.takeRetainedValue() as? NSString {
                for(var numberIndex: CFIndex = 0;numberIndex < ABMultiValueGetCount(phones); numberIndex++) {
                    var contact = AddressBookContactStruct()
                    contact.contactFullName = fullName as String
                    let phoneUnmanaged = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                    let phoneLabelUnmanaged = ABMultiValueCopyLabelAtIndex(phones, numberIndex)
                    let phoneNumber : NSString = phoneUnmanaged.takeRetainedValue() as! NSString
                    let phoneLabel : NSString = phoneLabelUnmanaged.takeRetainedValue() as NSString
                    let regex = NSRegularExpression(pattern: "[0-9]",
                        options: nil, error: nil)!
                    let regexLabel = NSRegularExpression(pattern: "[a-zA-Z0-9]",
                        options: nil, error: nil)!
                    let results = regex.matchesInString(phoneNumber as String,
                        options: nil, range: NSMakeRange(0, phoneNumber.length))
                    let resultsLabel = regexLabel.matchesInString(phoneLabel as String,
                        options: nil, range: NSMakeRange(0, phoneLabel.length))
                    
                    let mappedResults = map(results) { phoneNumber.substringWithRange($0.range)}
                    let strRepresentationResults = "".join(mappedResults)
                    
                    let mappedResultsLabel = map(resultsLabel) { phoneLabel.substringWithRange($0.range)}
                    let strRepresentationResultsLabel = "".join(mappedResultsLabel)
                    
                    var finalPhoneNumber = strRepresentationResults as NSString
                    var finalPhoneLabel = strRepresentationResultsLabel as NSString
                    
                    var range = NSRange()
                    if finalPhoneNumber.length > 10 {
                        range = NSRange(location: 1, length: finalPhoneNumber.length - 1)
                    } else {
                        range = NSRange(location: 0, length: finalPhoneNumber.length)
                    }
                    var ff = finalPhoneNumber.substringWithRange(range)
                    
                    contact.recordId = ff
                    contact.phoneLabel = String(finalPhoneLabel)
                    self.contactsArr.append(contact)
                }
//                println(self.contactsArr.map({$0.contactFullName}))
            }
        }
        return completionHandler(responseObject: self.contactsArr, error: nil)
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

