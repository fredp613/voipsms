//
//  KeyChainHelper.swift
//  Trasher
//
//  Created by Fred Pearson on 2014-12-16.
//  Copyright (c) 2014 Frederick Pearson. All rights reserved.
//

import Foundation
import Security

let SecMatchLimit: String! = kSecMatchLimit as String
let SecReturnData: String! = kSecReturnData as String
let SecValueData: String! = kSecValueData as String
let SecAttrAccessible: String! = kSecAttrAccessible as String
let SecClass: String! = kSecClass as String
let SecAttrService: String! = kSecAttrService as String
let SecAttrGeneric: String! = kSecAttrGeneric as String
let SecAttrAccount: String! = kSecAttrAccount as String

class KeyChainHelper {
    
    private struct internalVars {
        static var serviceName: String = ""
    }
    
    class var serviceName: String {
        get {
        if internalVars.serviceName.isEmpty {
        internalVars.serviceName = NSBundle.mainBundle().bundleIdentifier ?? "SwiftKeyChainHelper"
        }
        return internalVars.serviceName
        }
        set(newServiceName) {
            internalVars.serviceName = newServiceName
        }
    }
    
    class func setData(value: NSData, forKey: String) -> Bool {
        var keyChainQueryDictionary: NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(forKey)
        keyChainQueryDictionary[SecValueData] = value
        
        keyChainQueryDictionary[SecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
        
        let status: OSStatus = SecItemAdd(keyChainQueryDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return self.updateData(value, forKey: forKey)
        } else {
            return false
        }
    }
    
    class func createORupdateForKey(value: String, keyName: String) -> Bool {
        
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            return self.setData(data, forKey: keyName)
        }
        
        return false
    }
    
    class func deleteForKey(keyName: String) -> Bool {
        
        let keychainQueryDictionary : NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        let status: OSStatus = SecItemDelete(keychainQueryDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    class func retrieveForKey(keyName: String) -> String? {
        
        var keychainData: NSData? = self.dataForKey(keyName)
        var stringValue: String?
        if let data = keychainData {
            stringValue = NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        }
        
        return stringValue!
    }
    
    private class func updateData(value: NSData, forKey keyName: String) -> Bool {
        let keychainQueryDictionary: NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        let updateDictionary = [SecValueData: value]
        
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary, updateDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    private class func dataForKey(keyName: String) -> NSData? {
        
        var keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        
        // Specify we want NSData/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue
        
        // Search
        var searchResultRef: Unmanaged<AnyObject>?
        var keychainValue: NSData?
        
        let status: OSStatus = SecItemCopyMatching(keychainQueryDictionary, &searchResultRef)
        
        if status == noErr {
            if let resultRef = searchResultRef {
                keychainValue = resultRef.takeUnretainedValue() as? NSData
            }
        }
        
        return keychainValue;
        
    }
    
    private class func setupKeychainQueryDictionaryForKey(keyName: String) -> NSMutableDictionary {
        var keychainQueryDictionary: NSMutableDictionary = [SecClass:kSecClassGenericPassword]
        keychainQueryDictionary[SecAttrService] = KeyChainHelper.serviceName
        
        var encodedIdentifer: NSData? = keyName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifer
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifer
        
        return keychainQueryDictionary
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
