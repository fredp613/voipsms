//
//  CoreDID.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-25.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

enum didType : String {
    case PRIMARY = "Primary"
    case SUB = "Sub"
}

class CoreDID: NSManagedObject {

    @NSManaged var did: String
    @NSManaged var type: String
    @NSManaged var registeredOn: String
    @NSManaged var currentlySelected: NSNumber
    
    
    class func createInManagedObjectContext(managedObjectContext: NSManagedObjectContext, didnum: String, didtype: String, didRegisteredOn: String) -> Bool {
        
        let did : CoreDID = NSEntityDescription.insertNewObjectForEntityForName("CoreDID", inManagedObjectContext: managedObjectContext) as! CoreDID
        did.did = didnum
        did.type = didtype
        did.registeredOn = didRegisteredOn
        if didtype == "Primary" {
         
            did.currentlySelected = true
        } else {
         
            did.currentlySelected = false
        }

        
        if managedObjectContext.save(nil) {
            return true
        }
        return false
    }
    
    class func toggleSelected(moc: NSManagedObjectContext, did: String)  {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreDID")
        fetchRequest.returnsObjectsAsFaults = false
        var coreDIDs = [CoreDID]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreDID]
        if fetchResults?.count > 0 {
            coreDIDs = fetchResults!
            for c in coreDIDs {
                if c.did == did {
                    c.currentlySelected = 1
                    println(c.did + " is currently selected")
                } else {
                    c.currentlySelected = 0
                }
                moc.save(nil)
            }
        }
    }
    
    class func isExistingDID(managedObjectContext: NSManagedObjectContext, didnum: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreDID")
        fetchRequest.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "did == %@", didnum)
        fetchRequest.predicate = predicate
        
        let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: nil) as? [CoreDID]
        if fetchResults?.count > 0 {
            return true
        }
        return false
    }
    
    class func getSelectedDID(moc: NSManagedObjectContext) -> CoreDID? {
        let fetchRequest = NSFetchRequest(entityName: "CoreDID")
        fetchRequest.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "currentlySelected == %@", true)
        fetchRequest.predicate = predicate
        
        var coreDIDs = [CoreDID]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreDID]
        if fetchResults?.count > 0 {
            coreDIDs = fetchResults!
            return coreDIDs[0]
        }
        return nil
        
    }
    
    class func getDIDs(moc: NSManagedObjectContext) -> [CoreDID]? {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreDID")
        let entity = NSEntityDescription.entityForName("CoreDID", inManagedObjectContext: moc)
        fetchRequest.entity = entity

        
        fetchRequest.returnsObjectsAsFaults = false
        var coreDIDs = [CoreDID]()
        let fetchResults = moc.executeFetchRequest(fetchRequest, error: nil) as? [CoreDID]
        if fetchResults?.count > 0 {
            coreDIDs = fetchResults!
            return coreDIDs
        }
        return nil
    }
    
    class func currentDID(managedObjectContext: NSManagedObjectContext) -> CoreDID? {
        let fetchRequest = NSFetchRequest(entityName: "CoreDID")
        let predicate = NSPredicate(format: "type == %@", "Primary")
        fetchRequest.predicate = predicate
                
        var coreDIDs = [CoreDID]()
        var error : NSError? = nil
        if let fetchResults = managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [CoreDID] {
            coreDIDs = fetchResults
            if fetchResults.count > 0 {
                return coreDIDs[0]
            }
        } else {
            println("\(error?.userInfo)")
        }
        return nil
    }
    
    class func createOrUpdateDID(moc: NSManagedObjectContext) {
        
        let params = [
            "method": "getDIDsInfo"
        ]
  
        
        VoipAPI(httpMethod: httpMethodEnum.GET, url: APIUrls.get_request_url_contruct(params)!, params: nil).APIAuthenticatedRequest { (responseObject, error) -> () in
            
            let json = responseObject

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
                    }
                } else {
                    //some error to user
                }
            }
            
        }
    }
}
