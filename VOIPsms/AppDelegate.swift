//
//  AppDelegate.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData
import AddressBook

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var backgroundTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier()
    var did : String = String()
    let defaults = NSUserDefaults.standardUserDefaults()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //sync addressBook when opening
        if Contact().checkAccess() {
            Contact().syncAddressBook1()
        }
        
        if let currentUser = CoreUser.currentUser(moc) {
            currentUser.initialLoad = 1
            CoreUser.updateInManagedObjectContext(moc, coreUser: currentUser)
//            refreshMessages()

        }
        
        if let cds = CoreDevice.getTokens(self.moc) {
            println("tokens are")
            for c in cds {
                println(c.deviceToken)
            }
        }
        
//        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        //ask for contact access
        Contact().getContactsDict({ (contacts) -> () in
        })
        
        
//        if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
//            [self application:application didReceiveRemoteNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
//        }
        

        if let myDict = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
            println("from remote")
            println(myDict)
        } else {
            println("not from remote")
            // no notification
        }
        

        
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {

    }
    
   

//    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
//        println("house")
//        if (application.applicationState == UIApplicationState.Active) {
//            println("done")
//        } else {
//        // app was just brought from background to foreground
//            println("ross")
//        }
//        
//    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
//        NSString *job = [[userInfo valueForKey:@"aps"] valueForKey:@"job"];

        if (application.applicationState == UIApplicationState.Active) {
            self.createOrUpdateMessage(userInfo, userActive: true)
        } else {
            self.createOrUpdateMessage(userInfo, userActive: false)
            if let notificationContact = userInfo["contact"] as? String {
                println("contact is: " + notificationContact)
                if let notificationDID = userInfo["did"] as? String {
                    println("did is:" + notificationDID)
                    if let selectedDID = CoreDID.getSelectedDID(self.moc) {
                        println("selected DID is: " + selectedDID.did)
                        if selectedDID.did != notificationDID {
                            CoreDID.toggleSelected(self.moc, did: notificationDID)
                            if let currentUser = CoreUser.currentUser(self.moc) {
                                currentUser.notificationLoad = 1
                                currentUser.notificationDID = notificationDID
                                currentUser.notificationContact = notificationContact
                                CoreDataStack().saveContext(moc)
                            }
                        }
                       
                    }
                }
            }
        }
        
    }
    

    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.backgroundTaskID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskID)
        }
//          self.timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        let app = UIApplication.sharedApplication()
//        let oldNotifications = app.scheduledLocalNotifications
//        if oldNotifications.count > 0 {
//        app.cancelAllLocalNotifications()

//        }

//        refreshMessages()
        

       
        
    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        
        refreshMessages()
                    println("hi there active")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        //clear all notifications - refactor this - s/b only messages from open contact
//        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
//        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//        dispatch_async(backgroundQueue, { () -> Void in
        
        
//            if let str = CoreDID.getSelectedDID(self.moc) {
//                if let cm = CoreMessage.getMessagesByDID(self.moc, did: self.did).first {
//                    if let currentUser = CoreUser.currentUser(self.moc) {
//                        let lastMessage = cm
//                        var from = ""
//                        from = lastMessage.date
//                        Message.getMessagesFromAPI(false, fromList: true, moc: self.moc, from: from.strippedDateFromString(), completionHandler: { (responseObject, error) -> () in
//                            if currentUser.initialLogon.boolValue == true || currentUser.initialLoad.boolValue == true {
//                                currentUser.initialLoad = 0
//                                currentUser.initialLogon = 0
//                                CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
//                            }
//                            //                        self.pokeFetchedResultsController()
//                        })
//                    }
//                    
//                }
//            }
//        })
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        self.saveContext()
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        var characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        
        var deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
//        
//        if let cd = CoreDevice.createInManagedObjectContext(self.moc, device: deviceTokenString) {
//              println("Got token data! \(cd.deviceToken)")
//        }
        println(deviceToken)
        
        if let coreDevice = CoreDevice.createOrUpdateInMOC(self.moc, token: deviceTokenString) {
            println("got token data! \(coreDevice.deviceToken)")
        }

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("Couldn't register: \(error)")
    }
    
    //MARK: Custom methods
    func refreshMessages() {
        
    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            
            if let str = CoreDID.getSelectedDID(self.moc) {
                let fromStr = CoreMessage.getLastMsgByDID(self.moc, did: str.did)?.date.strippedDateFromString()
                Message.getMessagesFromAPI(true, fromList: false, moc: self.moc, from: fromStr) { (responseObject, error) -> () in
                }                        
            }
        })
    }
    
    func createOrUpdateMessage(userInfo: [NSObject : AnyObject], userActive: Bool) {
        println(userInfo)
        let did = userInfo["did"] as! String
        let id = userInfo["id"] as! String
        let message = userInfo["message"] as! String
        let contact = userInfo["contact"] as! String
        let date = userInfo["date"] as! String

        
        var flagValue = message_status.DELIVERED.rawValue
        if userActive {
            flagValue = message_status.READ.rawValue
        }
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            if !CoreMessage.isExistingMessageById(self.moc, id: id) && !CoreDeleteMessage.isDeletedMessage(self.moc, id: id) {
                CoreMessage.createInManagedObjectContext(self.moc, contact: contact, id: id, type: true, date: date, message: message, did: did, flag: flagValue, completionHandler: { (responseObject, error) -> () in
                    if let contactOfMessage = CoreContact.currentContact(self.moc, contactId: contact) {
                        var formatter1: NSDateFormatter = NSDateFormatter()
                        formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                            let parsedDate: NSDate = formatter1.dateFromString(date)!
                        contactOfMessage.lastModified = parsedDate
                        if contactOfMessage.deletedContact.boolValue {
                            contactOfMessage.deletedContact = 0
                        }
                        CoreContact.updateContactInMOC(self.moc)
                    } else {
                        CoreContact.createInManagedObjectContext(self.moc, contactId: contact, lastModified: date)
                    }
                })
            }
        })
        
    }
 


    

}

