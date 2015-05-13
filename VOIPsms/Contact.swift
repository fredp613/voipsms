//
//  Contact.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import UIKit

class Contact {
    
    var addressBook = APAddressBook()
    var access = APAddressBook.access()

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
  
    
    func getContactsArray(completionHandler: ([String: String]) -> ()){
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

    

}

