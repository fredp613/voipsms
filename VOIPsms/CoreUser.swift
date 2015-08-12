//
//  CoreUser.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData


class CoreUser: NSManagedObject {

    @NSManaged var email: String
    @NSManaged var apiPassword: String
    @NSManaged var token: String
    @NSManaged var remember: NSNumber
    @NSManaged var initialLogon: NSNumber
    @NSManaged var initialLoad: NSNumber
    @NSManaged var messagesLoaded: NSNumber
    @NSManaged var notificationLoad: NSNumber
    @NSManaged var notificationDID: String
    @NSManaged var notificationContact: String
    @NSManaged var notificationsFlag: NSNumber
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, email: String, pwd: String) -> Bool {
        
        let coreUser : CoreUser = NSEntityDescription.insertNewObjectForEntityForName("CoreUser", inManagedObjectContext: managedObjectContext) as! CoreUser
        
        coreUser.email = email
        coreUser.remember = true
        coreUser.initialLogon = true
        coreUser.notificationsFlag = true
        coreUser.messagesLoaded = false
        
        if managedObjectContext.save(nil) {

            KeyChainHelper.createORupdateForKey(pwd, keyName: email)
            //create dids
            return true
        }
        
        return false
    }
    
    class func deleteInManagedObjectContext(moc: NSManagedObjectContext, email: String) {
//        let coreUser : CoreUser 
    }
    
    class func logoutUser(managedObjectContext: NSManagedObjectContext, coreUser: CoreUser) {
        coreUser.remember = false
        if managedObjectContext.save(nil) {
        }
    }
    
    class func updateInManagedObjectContext(moc: NSManagedObjectContext, coreUser: CoreUser) {
//        if moc.save(nil) {
//        }
        CoreDataStack().saveContext(moc)
    }
    
    class func currentUser(managedObjectContext: NSManagedObjectContext) -> CoreUser? {
        //        let moc = CoreDataStack().managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "CoreUser")
        var coreUser = [CoreUser]()
        var error : NSError? = nil
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [CoreUser] {
            coreUser = fetchResults
            if fetchResults.count > 0 {
                return coreUser[0]
            }
        } else {
            println("\(error?.userInfo)")
        }
        return nil
    }
    
    
    class func verifyLoginCredentials() -> Bool {
        
        return false
    }
    
    class func userExists(moc: NSManagedObjectContext) -> Bool {
        if let currentUser = CoreUser.currentUser(moc) {
            return true
        }
        return false
    }
        
    
    class func authenticate(moc: NSManagedObjectContext, email: String, password: String, completionHandler: ((Bool, error: NSError?) -> Void)!) -> Void {
                
        var url = APIUrls.getUrl + "api_username=" + email + "&api_password=" + password + "&method=getDIDsInfo"
        
         VoipAPI(httpMethod: httpMethodEnum.GET, url: url, params: nil).APIAuthenticatedRequest { (data, error) -> () in
            if data != nil {
                println(data)

                if data["status"] == "success" {
                    
                    if self.userExists(moc) == false {
                        CoreUser.createInManagedObjectContext(moc, email: email, pwd: password)
                        
//                        CoreDID.createOrUpdateDID(moc)
                        let json = data
                        
                        for (index, (key: String, t: JSON)) in enumerate(json["dids"]) {
                            var type : String
                            if index == 0 {
                                type = didType.PRIMARY.rawValue
                            } else {
                                type = didType.SUB.rawValue
                            }
                            let did = t["did"].stringValue
                            
                            let registeredOn = t["order_date"].stringValue
                            let sms_enabled = t["sms_enabled"].stringValue
                            
                            if sms_enabled == "1" {
                                if !CoreDID.isExistingDID(moc, didnum: did) {
                                    CoreDID.createInManagedObjectContext(moc, didnum: did, didtype: type, didRegisteredOn: registeredOn)
                                    
                                    //here call your web service send the device id
                                }
                            } else {
                                // error should be something like, please enable SMS
                                return completionHandler(false, error:nil)
                                //some error to user
                            }
                        }
                    } else {
                        let currentUser = CoreUser.currentUser(moc)
                        currentUser?.remember = true
                        moc.save(nil)
                    }
                    return completionHandler(true, error: nil)
                } else {
                    return completionHandler(false, error: nil)
                }
                
            } else {
                println(error)
                return completionHandler(false, error: error)
            }
        }
        
    }
    
//    let json = responseObject
//    
//    for (index, (key: String, t: JSON)) in enumerate(json["dids"]) {
//    var type : String
//    if index == 0 {
//    type = didType.PRIMARY.rawValue
//    } else {
//    type = didType.SUB.rawValue
//    }
//    let did = t["did"].stringValue
//    
//    let registeredOn = t["order_date"].stringValue
//    let sms_enabled = t["sms_enabled"].stringValue
//    
//    if sms_enabled == "1" {
//    if !CoreDID.isExistingDID(moc, didnum: did) {
//    CoreDID.createInManagedObjectContext(moc, didnum: did, didtype: type, didRegisteredOn: registeredOn)
//    }
//    } else {
//    //some error to user
//    }
//    }


}
