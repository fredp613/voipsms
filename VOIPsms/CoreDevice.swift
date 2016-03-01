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
        let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreDevice]
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
        let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreDevice]
        if fetchResults?.count > 0 {
            coreDevices = fetchResults!
            return coreDevices
        }
        return nil
        
    }
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, device: String) -> CoreDevice? {
        
        let deviceMO : CoreDevice = NSEntityDescription.insertNewObjectForEntityForName("CoreDevice", inManagedObjectContext: managedObjectContext) as! CoreDevice
        deviceMO.deviceToken = device
        do {
            try managedObjectContext.save()
            
            return deviceMO
        } catch _ {
        }
        return nil
    }
    
    class func createOrUpdateInMOC(moc: NSManagedObjectContext, token: String) -> CoreDevice? {

        if let cu = CoreUser.currentUser(moc) {
            if let cd = CoreDevice.getToken(moc) {
                if cd.deviceToken != token {
                    cd.deviceToken = token
                    do {
                        try moc.save()
                        sendDeviceDetailsToAPI(token, user: cu, moc: moc)
                        return cd
                    } catch _ {
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
        print(deviceId)
        let qualityOfServiceClass = Int(QOS_CLASS_DEFAULT.rawValue)
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            if let did = CoreDID.getSelectedDID(moc) {
                print("hi we got a did" + did.did)
                if let api_password = KeyChainHelper.retrieveForKey(user.email) {
                    let params = [
                        "user":[
                            "email": user.email,
                            "pwd": api_password,
                            "did":did.did,
                            "device": deviceId
                        ]
                    ]
                    
                    let url = "https://mighty-springs-3852.herokuapp.com/users"
                    //                params should go in body of request
                    
                    VoipAPI(httpMethod: httpMethodEnum.POST, url: url, params: params).APIAuthenticatedRequest({ (responseObject, error) -> () in
                        print(responseObject)
                    })
                }
            }
        })
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
