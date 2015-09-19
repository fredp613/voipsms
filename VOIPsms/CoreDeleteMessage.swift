//
//  CoreDeleteMessage.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-10.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData

class CoreDeleteMessage: NSManagedObject {

    @NSManaged var id: String
    
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, id: String) -> Bool {
        
        let coreDeleteMessage : CoreDeleteMessage = NSEntityDescription.insertNewObjectForEntityForName("CoreDeleteMessage", inManagedObjectContext: moc) as! CoreDeleteMessage
        coreDeleteMessage.id = id
        
//        let err = NSError()
        do {
            try moc.save()
            return true
        } catch _ {
        }
        return false
    }
    
    class func deleteAllInManagedObjectContext(moc: NSManagedObjectContext, id: String) -> Bool {
        
        let fetchRequest = NSFetchRequest(entityName: "CoreDeleteMessage")
        let entity = NSEntityDescription.entityForName("CoreDeleteMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        var coreDeleteMessages = [CoreDeleteMessage]()
        let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreDeleteMessage]
        if fetchResults?.count > 0 {
            coreDeleteMessages = fetchResults!
        }
        for cm in coreDeleteMessages {
            moc.deleteObject(cm)
            do {
                try moc.save()
            } catch _ {
            }
            return true
        }
        return false
    }
    class func getAllDeletedMessages(moc: NSManagedObjectContext) -> [CoreDeleteMessage]? {
        let fetchRequest = NSFetchRequest(entityName: "CoreDeleteMessage")
        let entity = NSEntityDescription.entityForName("CoreDeleteMessage", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreDeleteMessage]()
        let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreDeleteMessage]
        if fetchResults?.count > 0 {
            coreMessages = fetchResults!
            return coreMessages
        }
        return nil
    }
//    CoreMessage.isDeletedMessageById(moc, id: id) == false **/
    class func isDeletedMessage(moc: NSManagedObjectContext, id: String) -> Bool {        
        let fetchRequest = NSFetchRequest(entityName: "CoreDeleteMessage")
        let entity = NSEntityDescription.entityForName("CoreDeleteMessage", inManagedObjectContext: moc)
        let predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = predicate
        fetchRequest.entity = entity
        fetchRequest.returnsObjectsAsFaults = false
        var coreMessages = [CoreDeleteMessage]()
        let fetchResults = (try? moc.executeFetchRequest(fetchRequest)) as? [CoreDeleteMessage]
        if fetchResults?.count > 0 {
            return true
        }
        return false
    }

}
