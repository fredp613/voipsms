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
    @NSManaged var notificationContact: String?
    @NSManaged var notificationsFlag: NSNumber
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, email: String, pwd: String) -> Bool {

        //deleteInManagedObjectContext(managedObjectContext, email: email)
        
        let coreUser : CoreUser = NSEntityDescription.insertNewObjectForEntityForName("CoreUser", inManagedObjectContext: managedObjectContext) as! CoreUser
        
        coreUser.email = email
        coreUser.remember = true
        coreUser.initialLogon = true
        coreUser.messagesLoaded = false
        if let _ = CoreDevice.getToken(managedObjectContext) {
            coreUser.notificationsFlag = true
        } else {
            coreUser.notificationsFlag = false
        }
        
        do {
            try managedObjectContext.save()

            KeyChainHelper.createORupdateForKey(pwd, keyName: email)
            //create dids
            return true
        } catch _ {
        }
        
        return false
    }
    
    class func deleteInManagedObjectContext(moc: NSManagedObjectContext, email: String) {
        if let coreUser : CoreUser = CoreUser.currentUser(moc) {
            moc.deleteObject(coreUser)
            do {
                try moc.save()
            } catch _ {
            }

        }
    }
    
    class func logoutUser(managedObjectContext: NSManagedObjectContext, coreUser: CoreUser) {
        coreUser.remember = false
        do {
            try managedObjectContext.save()
        } catch _ {
        }
    }
    
    class func updateInManagedObjectContext(moc: NSManagedObjectContext, coreUser: CoreUser) {
//        if moc.save(nil) {
//        }
        do {
            try moc.save()
        } catch _ {
        }
//        CoreDataStack().saveContext(moc)
    }
    
    class func currentUser(managedObjectContext: NSManagedObjectContext) -> CoreUser? {
//        let moc = CoreDataStack().managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "CoreUser")
//        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
//        fetchRequest.sortDescriptors = [sortDescriptor]
       
        do {
           let fetchResults = try managedObjectContext.executeFetchRequest(fetchRequest) as! [CoreUser]

            if fetchResults.count > 0 {
                return fetchResults[0]
            }
        }
        catch {
            print(error)            
        }
        
//        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest) as? [CoreUser] {
//            coreUser = fetchResults
//            if fetchResults.count > 0 {
//                return coreUser[0]
//            }
//        } else {
//            print("\(error?.userInfo)")
//        }
        return nil
    }
    
    
    class func verifyLoginCredentials() -> Bool {
        
        return false
    }
    
    class func userExists(moc: NSManagedObjectContext) -> Bool {
        if let _ = CoreUser.currentUser(moc) {
            return true
        }
        return false
    }
        
    
    class func authenticate(moc: NSManagedObjectContext, email: String, password: String, completionHandler: ((Bool, error: NSError?, status: String?) -> Void)!) -> Void {
        
        let url = APIUrls.getUrl + "api_username=" + email + "&api_password=" + password + "&method=getDIDsInfo"
        
         VoipAPI(httpMethod: httpMethodEnum.GET, url: url, params: nil).APIAuthenticatedRequest { (data, error) -> () in
            if data != nil {
                if data["status"] == "success" {
                    if self.userExists(moc) == false {
                        CoreUser.createInManagedObjectContext(moc, email: email, pwd: password)
                        let json = data
                        for (index, element: (_, t)) in json["dids"].enumerate() {
                            var dtype = ""
                            if index == 0 {
                                dtype = didType.PRIMARY.rawValue
                            } else {
                                dtype = didType.SUB.rawValue
                            }
                            let did = t["did"].stringValue
                            
                            let registeredOn = t["order_date"].stringValue
                            let sms_enabled = t["sms_enabled"].stringValue
                            let sms_available = t["sms_available"].stringValue
                            
                            if sms_enabled == "1" && sms_available == "1" {
                                if !CoreDID.isExistingDID(moc, didnum: did) {
                                    CoreDID.createInManagedObjectContext(moc, didnum: did, didtype: dtype, didRegisteredOn: registeredOn)
                                    
                                    //here call your web service send the device id
                                }
                            } else {
//
                                    return completionHandler(false, error:nil, status: "SMS Not Enabled, please verify your account settings")
                                    
                                
                                // error should be something like, please enable SMS
                                
                                //some error to user
                            }
                        }
                    } else {
                        let currentUser = CoreUser.currentUser(moc)
                        currentUser?.remember = true
                         KeyChainHelper.createORupdateForKey(password, keyName: email)
                        do {
                            try moc.save()
                        } catch _ {
                        }
                    }
                    return completionHandler(true, error: nil, status: "success")
                } else {
                    if data["status"] == "invalid_credentials" {
                        return completionHandler(false, error: nil, status: "invalid_credentials")
                    } else {
                        return completionHandler(false, error: nil, status: "api not enabled")
                    }

                }
                
            } else {
                return completionHandler(false, error: error, status: nil)
            }
        }
    }
    
    
}
