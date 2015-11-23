//
//  DownloadMessagesViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-27.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData


class DownloadMessagesViewController: UIViewController /**, NSFetchedResultsControllerDelegate **/ {
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var timer : NSTimer = NSTimer()
    var notificationCenter = NSNotificationCenter.defaultCenter()
    var totalCount : Int = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.startAnimating()
        self.notificationCenter.addObserver(self, selector: "contextDidSave:", name: NSManagedObjectContextWillSaveNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//        dispatch_async(backgroundQueue, { () -> Void in
        if Reachability.isConnectedToNetwork() {
             self.getMessages()
        }

        
//        })
        
    }      
    
    @IBAction func testPressed(sender: AnyObject) {
        print("testing")
    }
    func contextDidSave(notification: NSNotification) {
//        self.testBtn.setTitle(String(totalCount), forState: UIControlState.Normal)
//        if notification.name == NSManagedObjectContextWillSaveNotification {
//            println("yes")
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                println("main thread")
//                var c = CoreMessage.getMessages(self.moc, ascending: false).count
//                println(self.lblCount.text! + " - " + String(c))
//            })
        
//        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Custom Methods
    func getMessages() {                
        let backgroundMOC : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        if let dids = CoreDID.getDIDs(backgroundMOC) {
            if let str = dids.filter({$0.currentlySelected.boolValue == true}).first {
                if let currentUser = CoreUser.currentUser(backgroundMOC) {
                    Message.getMessagesFromAPI(false, fromList: false, moc: backgroundMOC, from: str.registeredOn.strippedDateFromString(), completionHandler: { (responseObject,
                        error) -> () in
                    
                        if error == nil {
                           
                            do {
                                 let contacts = try CoreContact.getAllContacts(backgroundMOC)
                                    for c in contacts! {
                                        if let lastMessage = CoreContact.getLastMessageFromContact(backgroundMOC, contactId: c.contactId, did: nil) {
                                            let formatter1: NSDateFormatter = NSDateFormatter()
                                            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                                            let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
                                            c.lastModified = parsedDate
                                            CoreContact.updateContactInMOC(backgroundMOC)
                                        }
                                    }
                                
                            } catch {
                                return
                            }
                            
                            if Contact().checkAccess() {
//                                Contact().syncAddressBook1(backgroundMOC)
                            }
                            
                            print("done")
                            currentUser.initialLogon = 0
                            currentUser.messagesLoaded = 1
                            CoreUser.updateInManagedObjectContext(backgroundMOC, coreUser: currentUser)
                           
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityIndicator.stopAnimating()
                                self.notificationCenter.removeObserver(self)
                                self.performSegueWithIdentifier("segueToMessages", sender: self)
                            })
                            
                        } else {
                            print(error)
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.showErrorController()
                            })
                        }
                    })
                }

            }

        }
    }
    
    func showErrorController() {
        let alertController = UIAlertController(title: "Network Error", message: "We are having trouble reaching the voip.ms servers, click Ok to try again or No to cancel to try again later", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            print("pressed")
            self.getMessages()
        }
        let cancelAction = UIAlertAction(title: "No, cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            print("cancelled")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }



    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
