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
//    var privateMoc : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    var remoteNotification : NSDictionary?

    var backgroundTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier()
    var did : String = String()
    let defaults = NSUserDefaults.standardUserDefaults()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
//        privateMoc.persistentStoreCoordinator = CoreDataStack().persistentStoreCoordinator
        let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        privateMOC.parentContext = moc
        
        if let currentUser = CoreUser.currentUser(moc) {
            currentUser.initialLoad = 1
            CoreUser.updateInManagedObjectContext(moc, coreUser: currentUser)
//            refreshMessages()
            //sync addressBook when opening
            privateMOC.performBlock { () -> Void in
                if Contact().checkAccess() {
                    Contact().syncAddressBook1(privateMOC)
                }
            }
            pingPushServer()
        }
        
        if let cds = CoreDevice.getTokens(moc) {
            print("tokens are")
            for c in cds {
                print(c.deviceToken)
            }
        }
        
//        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        //ask for contact access
        Contact().getContactsDict({ (contacts) -> () in
        })
        
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
//
//            let sb = UIStoryboard(name: "Main", bundle: nil)
//             NSNotificationCenter.defaultCenter().postNotificationName("appRestorePush", object: nil, userInfo: userInfo as [NSObject : AnyObject])
            
            let did = userInfo["did"] as! String
            let id = userInfo["id"] as! String
            let message = userInfo["message"] as! String
            let contact = userInfo["contact"] as! String
            let date = userInfo["date"] as! String

            let navController = window?.rootViewController as! UINavigationController
            let firstVC = navController.viewControllers[0] as! MessageListViewController
            
            firstVC.did = did
            firstVC.contactForSegue = contact
            firstVC.fromClosedState = true
            firstVC.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
         
        }
       
        

        

        
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {

    }
    
 
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        remoteNotification = userInfo
        
        
        
        if (application.applicationState == UIApplicationState.Active) {
            self.createOrUpdateMessage(userInfo, userActive: true)
        } else {
            self.createOrUpdateMessage(userInfo, userActive: false)
//            if let notificationContact = userInfo["contact"] as? String {
//                println("contact is: " + notificationContact)
//                if let notificationDID = userInfo["did"] as? String {
//                    println("did is:" + notificationDID)
//                    if let selectedDID = CoreDID.getSelectedDID(self.moc) {
//                        println("selected DID is: " + selectedDID.did)
//                        if selectedDID.did != notificationDID {
//                            CoreDID.toggleSelected(self.moc, did: notificationDID)
//                            if let currentUser = CoreUser.currentUser(self.moc) {
//                                currentUser.notificationLoad = 1
//                                currentUser.notificationDID = notificationDID
//                                currentUser.notificationContact = notificationContact
//                                CoreDataStack().saveContext(moc)
//                            }
//                        }
//                       
//                    }
//                }
//            }
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
        
//        if remoteNotification != nil {
//            println("ok we are golen")
//            let sb = UIStoryboard(name: "Main", bundle: nil)
//            let mnvc = sb.instantiateViewControllerWithIdentifier("mnvc") as! UINavigationController
//            let messageListVC: MessageListViewController = mnvc.viewControllers[0] as!
//            MessageListViewController
//            if let notificationContact = remoteNotification?["contact"] as? String {
//                println("contact is:" + notificationContact)
//                if let notificationDID = remoteNotification?["did"] as? String {
//                    println("did is:" + notificationDID)
//                    messageListVC.navToDetailFromNotification(notificationDID, contact: notificationContact)
//                }
//            }
//        }
        

        refreshMessages()

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        self.saveContext()
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        
        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
//        
//        if let cd = CoreDevice.createInManagedObjectContext(self.moc, device: deviceTokenString) {
//              println("Got token data! \(cd.deviceToken)")
//        }
        print(deviceToken)
        
        if let coreDevice = CoreDevice.createOrUpdateInMOC(self.moc, token: deviceTokenString) {
            print("got token data! \(coreDevice.deviceToken)")
        }

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Couldn't register: \(error)")
    }
    
    //MARK: Custom methods
    func refreshMessages() {
        if let str = CoreDID.getSelectedDID(moc) {
            let fromStr = CoreMessage.getLastMsgByDID(self.moc, did: str.did)?.date.strippedDateFromString()
            Message.getMessagesFromAPI(true, fromList: false, moc: self.moc, from: fromStr) { (responseObject, error) -> () in
            }
        }
    }
    
    func createOrUpdateMessage(userInfo: [NSObject : AnyObject], userActive: Bool) {
        print(userInfo)
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
    
    func pingPushServer() {
        let url = "https://mighty-springs-3852.herokuapp.com/users"
        //                params should go in body of request
        
        VoipAPI(httpMethod: httpMethodEnum.GET, url: url, params: nil).APIAuthenticatedRequest({ (responseObject, error) -> () in
            if responseObject != nil {
                print(responseObject)
            }
            if error != nil {
                print(error)
            }

        })
    }
 


    

}

