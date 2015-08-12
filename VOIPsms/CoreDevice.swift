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
        if let cd = CoreDevice.getToken(moc) {
            if cd.deviceToken != token {
                cd.deviceToken = token
                moc.save(nil)
            }
        } else {
            //create
            if let cd = CoreDevice.createInManagedObjectContext(moc, device: token) {
                println("deviced saved in MOC \(cd.deviceToken)")
            }
        }
        
        return nil
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
