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
    var remoteNotification : NSDictionary?

    var backgroundTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier()
    var did : String = String()
    let defaults = NSUserDefaults.standardUserDefaults()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        privateMOC.parentContext = moc
        
        if let currentUser = CoreUser.currentUser(moc) {
            currentUser.initialLoad = 1
            CoreUser.updateInManagedObjectContext(moc, coreUser: currentUser)
//            refreshContacts(privateMOC)
            refreshDeviceTokenOnServer(currentUser)
        }
        
        if let cds = CoreDevice.getTokens(moc) {
            print("tokens are")
            for c in cds {
                print(c.deviceToken)
            }
        }
        
    
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        //ask for contact access
        
//        Contact().getContactsDict({ (contacts) -> () in
//        })
        Contact().addressBookAccess();
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
            
            let did = userInfo["did"] as! String
            let contact = userInfo["contact"] as! String
            let navController = window?.rootViewController as! UINavigationController
            let firstVC = navController.viewControllers[0] as! MessageListViewController
            firstVC.did = did
            firstVC.contactForSegue = contact
            firstVC.fromClosedState = true
            firstVC.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
            //clear notifications
//            application.cancelAllLocalNotifications()
        }
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {

    }
    
    
 
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        remoteNotification = userInfo

        print("receive")
        
        if (application.applicationState == UIApplicationState.Active) {
            self.createOrUpdateMessage(userInfo, userActive: true)
        } else {
            self.createOrUpdateMessage(userInfo, userActive: false)
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
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        
        if let currentUser = CoreUser.currentUser(moc) {
            currentUser.initialLoad = 1
            CoreUser.updateInManagedObjectContext(moc, coreUser: currentUser)
            let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            privateMOC.parentContext = moc
//            refreshContacts(privateMOC)
            refreshDeviceTokenOnServer(currentUser)
            print(currentUser)
            print("hi im in the foregroud");
        }
    
    }

    func applicationDidBecomeActive(application: UIApplication) {
        refreshMessages()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func saveContext() {
        do {
            try self.moc.save()
        } catch _ {
        }
        
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        print("yes")
        print(notificationSettings)
        
        if (notificationSettings.types != UIUserNotificationType.None) {
            print("did register user")
            application.registerForRemoteNotifications()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        
        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String

        if let coreDevice = CoreDevice.createOrUpdateInMOC(self.moc, token: deviceTokenString) {
            print("got token data! \(coreDevice.deviceToken)")
            if let currentUser = CoreUser.currentUser(self.moc) {
                refreshDeviceTokenOnServer(currentUser)
            }
        }

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Couldn't register: \(error)")
    }
    
    //MARK: Custom methods
    func refreshMessages() {
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            if let str = CoreDID.getSelectedDID(self.moc) {
                if let lastMsg = CoreMessage.getLastMsgByDID(self.moc, did: str.did) {
                    
                    let fromStr = lastMsg.date.strippedDateFromString()
                    print("MESSAGE FROM DATE IS: \(fromStr)")
                    Message.getMessagesFromAPI(true, fromList: false, moc: self.moc, from: fromStr) { (responseObject, error) -> () in
                    }
                } else {
                    print("MESSAGE FROM DATE IS NIL FOR SURE")
                    Message.getMessagesFromAPI(true, fromList: false, moc: self.moc, from: nil) { (responseObject, error) -> () in
                    }
                }
            }
        })
        
        
    }
    
    func refreshContacts(privateMOC: NSManagedObjectContext) {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
           
            privateMOC.performBlock { () -> Void in
//                autoreleasepool({ () -> () in
                    if Contact().checkAccess() {
                        Contact().loadAddressBook(privateMOC, completionHandler: { (responseObject, error) in
                            print("contacts loaded app delegate")
                        })
//                        Contact().syncAddressBook1(privateMOC)
                    }
//                })
                
                
            }
        })
    }
    
    func createOrUpdateMessage(userInfo: [NSObject : AnyObject], userActive: Bool) {
        let did = userInfo["did"] as! String
        let id = userInfo["id"] as! String
        let message = userInfo["message"] as! String
        let contact = userInfo["contact"] as! String
        let date = userInfo["date"] as! String
        
        var flagValue = message_status.DELIVERED.rawValue
        if userActive {
            flagValue = message_status.READ.rawValue
        }

            if !CoreMessage.isExistingMessageById(moc, id: id) && !CoreDeleteMessage.isDeletedMessage(moc, id: id) {
                CoreMessage.createInManagedObjectContext(moc, contact: contact, id: id, type: true, date: date, message: message, did: did, flag: flagValue, completionHandler: { (responseObject, error) -> () in
                    if let contactOfMessage = CoreContact.currentContact(self.moc, contactId: contact) {
                        let formatter1: NSDateFormatter = NSDateFormatter()
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
        
        handlePushNotification(userInfo)
    }
    
    func handlePushNotification(userInfo: [NSObject : AnyObject]) {
        let appState = UIApplication.sharedApplication().applicationState
        
        if appState == UIApplicationState.Inactive || appState == UIApplicationState.Background {
            NSNotificationCenter.defaultCenter().postNotificationName("appRestorePush", object: nil, userInfo: userInfo)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("appOpenPush", object: nil, userInfo: userInfo)
        }

    }
    
       
    func refreshDeviceTokenOnServer(currentUser: CoreUser) {

        if UIApplication.sharedApplication().respondsToSelector(#selector(UIApplication.currentUserNotificationSettings)) {
            if let grantedSettings = UIApplication.sharedApplication().currentUserNotificationSettings() {
                if grantedSettings.types != UIUserNotificationType.None {
                    if let deviceToken = CoreDevice.getToken(self.moc) {
                        print("device is: \(deviceToken.deviceToken)")
                        CoreDevice.sendDeviceDetailsToAPI(deviceToken.deviceToken, user: currentUser, moc: self.moc)
                    } else {
                        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories: nil)
                        
                        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                    }
                    currentUser.notificationsFlag = true
                    do {
                        try self.moc.save()
                    } catch _ {
                    }
                    
                } else {
                    currentUser.notificationsFlag = false
                    do {
                        try self.moc.save()
                    } catch _ {
                    }

                }
            }
            
        }
    }

}

