//
//  AppDelegate.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.


        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: []))
        
        return true
    }
    
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        println("received notification")
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: []))
        if let currentUser = CoreUser.currentUser(moc) {
            if !currentUser.initialLogon.boolValue {
                println("not inital logon")
                var timer : NSTimer = NSTimer()
                if Reachability.isConnectedToNetwork() {
                    timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
                }
            } else {
                println("is initial logon")
            }
            
        }
        
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        let app = UIApplication.sharedApplication()
//        let oldNotifications = app.scheduledLocalNotifications
//        if oldNotifications.count > 0 {
        app.cancelAllLocalNotifications()

//        }
    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        self.saveContext()
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println(deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("failed")
    }
    
    //MARK: Custom methods
    func timerDidFire(sender: NSTimer) {
        var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        if let str = CoreDID.getSelectedDID(moc) {
            let fromStr = CoreMessage.getLastMsgByDID(moc, did: str.did)?.date.strippedDateFromString()
            Message.getMessagesFromAPI(true, moc: moc, from: fromStr) { (responseObject, error) -> () in
            }
        }
    }
    
//    func notificationsAreOk() -> Bool {
//        let wishedTypes = UIUserNotificationType.Badge |
//            UIUserNotificationType.Alert |
//            UIUserNotificationType.Sound;
//        let application = UIApplication.sharedApplication()
//        let settings = application.currentUserNotificationSettings()
//        if settings == nil {
//            return false
//        }
//        if settings.types != wishedTypes {
//            return false
//        }
//        return true
//    }

    

}

