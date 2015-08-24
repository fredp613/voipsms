//
//  CoreDevice.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-08-09.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

class CoreDevice: NSManagedObject {

    @NSManaged var deviceToken: String
    
    class func getToken(moc: NSManagedObjectContext) -> CoreDevice? {
        let fetchRequest = NSFetchRequest(entityName: "CoreDevice")
        fetchRequest.returnsObjectsAsFaults = false
        
        var coreDevices = [CoreDevice]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreDevice]
        if fetchResults?.count > 0 {
            coreDevices = fetchResults!
            return coreDevices[0]
        }
        return nil
        
    }
    
    class func getTokens(moc: NSManagedObjectContext) -> [CoreDevice]? {
        let fetchRequest = NSFetchRequest(entityName: "CoreDevice")
        fetchRequest.returnsObjectsAsFaults = false
        
        var coreDevices = [CoreDevice]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreDevice]
        if fetchResults?.count > 0 {
            coreDevices = fetchResults!
            return coreDevices
        }
        return nil
        
    }
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, device: String) -> CoreDevice? {
        
        let deviceMO : CoreDevice = NSEntityDescription.insertNewObjectForEntityForName("CoreDevice", inManagedObjectContext: managedObjectContext) as! CoreDevice
        deviceMO.deviceToken = device
        if managedObjectContext.save(nil) {
            
            return deviceMO
        }
        return nil
    }
    
    class func createOrUpdateInMOC(moc: NSManagedObjectContext, token: String) -> CoreDevice? {
        println("this is being called")
        if let cu = CoreUser.currentUser(moc) {
            if let cd = CoreDevice.getToken(moc) {
                if cd.deviceToken != token {
                    cd.deviceToken = token
                    if moc.save(nil) {
                        sendDeviceDetailsToAPI(token, user: cu, moc: moc)
                        return cd
                    } else {
                        return nil
                    }
                }
            } else {
                //create
                if let cd = CoreDevice.createInManagedObjectContext(moc, device: token) {
                    sendDeviceDetailsToAPI(token, user: cu, moc: moc)
                    return cd
                } else {
                    return nil
                }
            }
        }
        return nil
    }
    
    
    class func sendDeviceDetailsToAPI(deviceId: String, user: CoreUser, moc: NSManagedObjectContext) {
        println(deviceId)
        var qualityOfServiceClass = Int(QOS_CLASS_DEFAULT.value)
        var backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            if let did = CoreDID.getSelectedDID(moc) {
                println("hi we got a did" + did.did)
                if let api_password = KeyChainHelper.retrieveForKey(user.email) {
                    let params = [
                        "user":[
                            "email": user.email,
                            "pwd": api_password,
                            "did":did.did,
                            "device": deviceId
                        ]
                    ]
                    var url = "http://nodejs-voipsms.rhcloud.com/users"
                    //                params should go in body of request
                    
                    VoipAPI(httpMethod: httpMethodEnum.POST, url: url, params: params).APIAuthenticatedRequest({ (responseObject, error) -> () in
                        println(responseObject)
                    })
                }
            }
        })
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
