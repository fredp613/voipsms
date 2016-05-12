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
//    init() {
//
//    }
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
//        let propertyType: NSNumber = kABMultiStringPropertyType
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
//        var success:Bool = false
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
    
    func addressBookAccess() {
        switch ABAddressBookGetAuthorizationStatus(){
        case .Authorized:
            print("Already authorized")
            /* Access the address book */
        case .Denied:
            print("Denied access to address book")
        case .NotDetermined:
            
            if let theBook: ABAddressBookRef = addressBook{
                ABAddressBookRequestAccessWithCompletion(theBook,
                 {(granted: Bool, error: CFError!) in
                    
                    if granted{
                        print("Access granted")
                    } else {
                        print("Access not granted")
                    }
                    
                })
            }
            
        case .Restricted:
            print("Access restricted")
            
        default:
            print("Other Problem")
        }
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

        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        let people = ABAddressBookCopyArrayOfAllPeople(adbk).takeRetainedValue() as [ABRecord]
        print("get all contacts called")
        autoreleasepool {
            for person in people {
    
                if let fullName : CFString = ABRecordCopyCompositeName(person)?.takeRetainedValue() {
                    
                    let name : NSString = fullName as NSString

                    if let keyword = keyword {
                        if name.lowercaseString.rangeOfString(keyword.lowercaseString) != nil {
                            let abContact = AddressBookContactStruct()
                            abContact.contactFullName = fullName as String
                            abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                            self.contactsArr.append(abContact)
                        }
                    } else {
                        let abContact = AddressBookContactStruct()
                        abContact.contactFullName = fullName as String
                        abContact.recordId = String(ABRecordGetRecordID(person).toIntMax())
                        self.contactsArr.append(abContact)
                    }
                }
            }
        }
        return self.contactsArr
    }
    
//    func syncAddressBook1(moc: NSManagedObjectContext) {
//
//        do {
//            if let coreContacts = try CoreContact.getAllContacts(moc) {
//                
//                autoreleasepool {
//                
//                    for cc in coreContacts {
//
//                        self.loadAddressBook { (responseObject, error) -> () in
//                            let contacts = responseObject
//                            print(error)
//                            let filteredArray = contacts.filter() {$0.recordId == cc.contactId}
//                            if filteredArray.count > 0 {
//                                let fullName = filteredArray.map({$0.contactFullName}).last!
//                                let phoneLabel = filteredArray.map({$0.phoneLabel}).last!
//                                cc.fullName = fullName
//                                cc.phoneLabel = phoneLabel
//                                cc.addressBookSyncLastModified = NSDate()
//                                // CoreContact.updateContactInMOC(moc)
//                            }
//                            if cc.fullName != "" || cc.fullName != nil {
//                                //contact has full name - check if still in addressbook, if not update fullName to nil
//                                if filteredArray.count == 0 {
//                                    cc.fullName = nil
//    //                                CoreContact.updateContactInMOC(moc)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                do {
//                    try moc.save()
//                } catch _ {
//                    print("somethign wrong")
//                }
//            }
//
//        } catch {
//        }
//        
//        
//    }
    
    func syncNewMessageContact(contact: CoreContact, moc: NSManagedObjectContext) -> Bool {
        
        var success = false
//        if self.checkAccess() {
            self.loadAddressBook(moc, completionHandler: { (responseObject, error) in
                let contacts = responseObject
                print(error)
                let filteredArray = contacts.filter() {$0.recordId == contact.contactId}
                if filteredArray.count > 0 {
                    //make sure to only grab the last contact in case of duplicates in the address book - refactor this later to allow the user to choose which contact they want to assign the message to
                    let fullName = filteredArray.map({$0.contactFullName}).last!
                    let phoneLabel = filteredArray.map({$0.phoneLabel}).last!
                    contact.fullName = fullName
                    contact.phoneLabel = phoneLabel
                    contact.addressBookSyncLastModified = NSDate()
                    CoreContact.updateContactInMOC(moc)
                    success = true
                }
            })
//        }
        return success
    }
    
    func contactName(contact :APContact) -> String {
        if let firstName = contact.firstName, lastName = contact.lastName {
            return "\(firstName) \(lastName)"
        }
        else if let firstName = contact.firstName {
            return "\(firstName)"
        }
        else if let lastName = contact.lastName {
            return "\(lastName)"
        }
        else {
            return ""
        }
    }
    
    func loadAddressBook(moc: NSManagedObjectContext, completionHandler: (responseObject: [AddressBookContactStruct], error: NSError?) -> ()) {

        do {
            if let coreContacts = try CoreContact.getAllContacts(moc) {
        
                self.addressBook.loadContacts(
                    { (contacts: [AnyObject]!, error: NSError!) in
                        if let unwrappedContacts = contacts {
                            
                            for c in unwrappedContacts {

                                for phone in c.phones {
                                    
                                    let regex = try! NSRegularExpression(pattern: "[0-9]",
                                        options: [])
                                    let pStr = phone as! NSString
                                    let results = regex.matchesInString(phone as! String,
                                        options: [], range: NSMakeRange(0, pStr.length))
                                    let mappedResults = results.map { pStr.substringWithRange($0.range)}
                                    let strRepresentationResults = mappedResults.joinWithSeparator("")
                                    
                                    let contact = AddressBookContactStruct()
                                    contact.contactFullName = self.contactName(c as! APContact)
                                    contact.recordId = strRepresentationResults
                                    print(phone)
                                    for cc in coreContacts {
                                        if cc.contactId == strRepresentationResults {
                                            cc.fullName = self.contactName(c as! APContact)
                                            CoreContact.updateContactInMOC(moc)
                                        
                                        }
                                    }
                                    
                                    self.contactsArr.append(contact)
                                }
                                
                            }
                            
                            return completionHandler(responseObject: self.contactsArr, error: nil)
                        }
                        if let unwrappedError = error {
                            return completionHandler(responseObject: self.contactsArr, error: unwrappedError)
                        }
                })
            }
        } catch {
            
        }
       
    }
    
    func getContactsBySearchString(searchTerm: String, moc: NSManagedObjectContext, completionHandler: (data: [AddressBookContactStruct]?) -> ()) {
        var addressBookData : [AddressBookContactStruct] = [AddressBookContactStruct]()
        Contact().loadAddressBook(moc) { (responseObject, error) in
            
            for record in responseObject {
                if record.contactFullName.rangeOfString(searchTerm) != nil {
                    addressBookData.append(record)
                }
                if record.recordId.rangeOfString(searchTerm) != nil {
                    addressBookData.append(record)
                }
            }
            
            if addressBookData.count > 0 {
                self.contactsArr = addressBookData
                return completionHandler(data: self.contactsArr)
            } else {
                return completionHandler(data: nil)
            }
            
        }
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
            for _ in self.coreContacts {
            }
            return self.coreContacts
        }
        
        return nil
        
    }
    

    
   
    

}

