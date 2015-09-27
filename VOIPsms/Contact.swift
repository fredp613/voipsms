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

        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
        let newContact:ABRecordRef! = ABPersonCreate().takeRetainedValue()
        var success:Bool = false

        success = ABRecordSetValue(newContact, kABPersonFirstNameProperty, firstName, &error)
        success = ABRecordSetValue(newContact, kABPersonLastNameProperty, lastName, &error)
        let propertyType: NSNumber = kABMultiStringPropertyType
        let phoneNumbers: ABMutableMultiValueRef =  createMultiStringRef()
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
        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        let rid : ABRecordID = NSNumber(integer: Int(recordId)!).intValue
        let existingContact : ABRecord = ABAddressBookGetPersonWithRecordID(adbk, rid).takeUnretainedValue()
        var success:Bool = false
        let phones: AnyObject = ABRecordCopyValue(existingContact, kABPersonPhoneProperty).takeRetainedValue()
        let phone1: ABMutableMultiValue = ABMultiValueCreateMutableCopy(phones).takeRetainedValue()
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
                            let regex = try! NSRegularExpression(pattern: "[0-9]",
                                options: [])
                            let pStr = p as! NSString
                            let results = regex.matchesInString(p as! String,
                                options: [], range: NSMakeRange(0, pStr.length))
                            let mappedResults = results.map { pStr.substringWithRange($0.range)}
                            let strRepresentationResults = mappedResults.joinWithSeparator("")
                            contactsDict.updateValue("\(c.firstName) \(c.lastName)", forKey:strRepresentationResults)
                        }
                    }
                    return completionHandler(contactsDict)
                }
        })
    }
    func getAllContacts(keyword: String?) -> [AddressBookContactStruct] {
//        var tstStr = [NSString]()
        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        let people = ABAddressBookCopyArrayOfAllPeople(adbk).takeRetainedValue() as NSArray as [ABRecord]
//        let phones: ABMultiValueRef = ABRecordCopyValue(people, kABPersonPhoneProperty) as! ABMultiValueRef
        print("get all contacts called")
        for person in people {
            
//            let fullName : CFString = ABRecordCopyCompositeName(person).takeRetainedValue()
//            let nizame : NSString = fullName as NSString
//            print(nizame)
            
            if let fullName : CFString = ABRecordCopyCompositeName(person)?.takeRetainedValue() {
                
                let name : NSString = fullName as NSString

                if let keyword = keyword {
                    if name.lowercaseString.rangeOfString(keyword.lowercaseString) != nil {
                        let abContact = AddressBookContactStruct()
                        abContact.contactFullName = fullName as String
                        abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                        self.contactsArr.append(abContact)
                    } /**else {
                        var abContact = AddressBookContactStruct()
                        abContact.contactFullName = fullName as String
                        abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                        self.contactsArr.append(abContact)
                    }**/
                } else {
                    let abContact = AddressBookContactStruct()
                    abContact.contactFullName = fullName as String
                    abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                    self.contactsArr.append(abContact)
                }
            }
        }
        return self.contactsArr
    }
    
    func syncAddressBook1(moc: NSManagedObjectContext) {
        print("called")
        do {
            if let coreContacts = try CoreContact.getAllContacts(moc) {

                for cc in coreContacts {

                    self.loadAddressBook { (responseObject, error) -> () in

                        let contacts = responseObject
                        let filteredArray = contacts.filter() {$0.recordId == cc.contactId}
                        if filteredArray.count > 0 {
                            let fullName = filteredArray.map({$0.contactFullName}).last!
                            let phoneLabel = filteredArray.map({$0.phoneLabel}).last!
                            CoreContact.updateInManagedObjectContext(moc, contactId: cc.contactId, lastModified: nil, fullName: fullName, phoneLabel: phoneLabel, addressBookLastModified: NSDate())
                        }
                        
                        
                    }
                }
            }

        } catch {
            
        }
        
        
    }
    
    func loadAddressBook(completionHandler: (responseObject: [AddressBookContactStruct], error: NSError?) -> ()) {

        let moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        var cs : [String] = [String]()
        
        struct contactS {
            var phone : String
            var fullName : String
        }
        
        let people = ABAddressBookCopyArrayOfAllPeople(adbk).takeRetainedValue() as NSArray as [ABRecord]
        for person in people {
            var lastMod: NSDate = (ABRecordCopyValue(person, kABPersonModificationDateProperty).takeRetainedValue() as? NSDate)!
            let phones : ABMultiValueRef = ABRecordCopyValue(person, kABPersonPhoneProperty).takeRetainedValue() as ABMultiValueRef
            if let fullName = ABRecordCopyCompositeName(person)?.takeRetainedValue() {
//                let name : NSString = fullName1 as NSString
                for(var numberIndex: CFIndex = 0;numberIndex < ABMultiValueGetCount(phones); numberIndex++) {
                    let contact = AddressBookContactStruct()
                    contact.contactFullName = fullName as String
                    let phoneUnmanaged = ABMultiValueCopyValueAtIndex(phones, numberIndex)
                    let phoneLabelUnmanaged = ABMultiValueCopyLabelAtIndex(phones, numberIndex)
                    let phoneNumber : NSString = phoneUnmanaged.takeRetainedValue() as! NSString
                    let phoneLabel : NSString = phoneLabelUnmanaged.takeRetainedValue() as NSString
                    let regex = try! NSRegularExpression(pattern: "[0-9]",
                        options: [])
                    let regexLabel = try! NSRegularExpression(pattern: "[a-zA-Z0-9]",
                        options: [])
                    let results = regex.matchesInString(phoneNumber as String,
                        options: [], range: NSMakeRange(0, phoneNumber.length))
                    let resultsLabel = regexLabel.matchesInString(phoneLabel as String,
                        options: [], range: NSMakeRange(0, phoneLabel.length))
                    
                    let mappedResults = results.map { phoneNumber.substringWithRange($0.range)}
                    let strRepresentationResults = mappedResults.joinWithSeparator("")
                    
                    let mappedResultsLabel = resultsLabel.map { phoneLabel.substringWithRange($0.range)}
                    let strRepresentationResultsLabel = mappedResultsLabel.joinWithSeparator("")
                    
                    let finalPhoneNumber = strRepresentationResults as NSString
                    let finalPhoneLabel = strRepresentationResultsLabel as NSString
                    
                    var range = NSRange()
                    if finalPhoneNumber.length > 10 {
                        range = NSRange(location: 1, length: finalPhoneNumber.length - 1)
                    } else {
                        range = NSRange(location: 0, length: finalPhoneNumber.length)
                    }
                    let ff = finalPhoneNumber.substringWithRange(range)
                    
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
                            let regex = try! NSRegularExpression(pattern: "[0-9]",
                                options: [])
                            let pStr = p as! NSString
                            let results = regex.matchesInString(p as! String,
                                options: [], range: NSMakeRange(0, pStr.length))
                            let mappedResults = results.map { pStr.substringWithRange($0.range)}
                            let strRepresentationResults = mappedResults.joinWithSeparator("")
                            contactsDict.updateValue("\(c.firstName) \(c.lastName)", forKey: strRepresentationResults)
                        }
                    }
                    for (key, value) in contactsDict {
                        if (value.rangeOfString(self.searchTerm) != nil) {
                            if let contact1 = CoreContact.currentContact(moc, contactId: key) {
                                if !self.coreContacts.contains(contact1) {
                                    self.coreContacts.append(contact1)
                                }
                            }
                        }
                    }
                    return completionHandler(self.coreContacts)
                }
        })
        
        if self.coreContacts.count > 0 {
            for c in self.coreContacts {
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

