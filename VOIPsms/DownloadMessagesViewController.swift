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
     let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).moc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

//        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//        dispatch_async(backgroundQueue, { () -> Void in
            if Reachability.isConnectedToNetwork() {
                
                 self.getMessages()
            } else {
    //            showErrorController()            
                self.performSegueWithIdentifier("segueToMessages", sender: self)
            }
//        })
        
    }      
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pingServerTempFunc(user: CoreUser) {
        if let api_password = KeyChainHelper.retrieveForKey(user.email) {
            let params = [
                "user":[
                    "email": user.email,
                    "pwd": api_password,
                    "did":"6666666666",
                    "device": "42343223423432"
                ]
            ]
            
            let url = "https://mighty-springs-3852.herokuapp.com/users"
            //                params should go in body of request
            
            VoipAPI(httpMethod: httpMethodEnum.POST, url: url, params: params).APIAuthenticatedRequest({ (responseObject, error) -> () in
//                print(responseObject)
            })
        }
    }
    
    //MARK: Custom Methods
    func getMessages() {
        
//        let backgroundMOC1 : NSManagedObjectContext = CoreDataStack().managedObjectContext!
       
        
        if let _ = CoreUser.currentUser(self.moc) {
            CoreDID.createOrUpdateDID(self.moc)
//             self.pingServerTempFunc(user)
        }
        if let dids = CoreDID.getDIDs(self.moc) {
//             print(dids)
            if let str = dids.filter({$0.currentlySelected.boolValue == true}).first {
                if let currentUser = CoreUser.currentUser(self.moc) {
                    Message.getMessagesFromAPI(false, fromList: false, moc: self.moc, from: str.registeredOn.strippedDateFromString(), completionHandler: { (responseObject,
                        error) -> () in
                        
                        if error == nil {
                           
                            do {//
                                if let contacts = try CoreContact.getAllContacts(self.moc) {
                                    for c in contacts {
                                        if let lastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: nil) {
                                            let formatter1: NSDateFormatter = NSDateFormatter()
                                            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                                            let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
                                            c.lastModified = parsedDate
                                            CoreContact.updateContactInMOC(self.moc)
//
                                        }
                                    }
                                }
                                
                            } catch {
                                print("DEBUG--------------ERROR IN DOWNLOAD VIEW CONTROLLER")
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.showErrorController()
                                })

                                return
                            }
                            
                            
//                            print("done")
                            currentUser.initialLogon = 0
                            currentUser.messagesLoaded = 1
                            CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
                           
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityIndicator.stopAnimating()
                                self.notificationCenter.removeObserver(self)
                                self.performSegueWithIdentifier("segueToMessages", sender: self)
//                            })
                            
                        } else {
                            print(error)
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.showErrorController()
//                            })
                        }
                    })
                    currentUser.initialLogon = 0
                    currentUser.messagesLoaded = 1
                    CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)

                }

            }

        } else {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
                self.dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertView(title: "Fatal Error", message: "issue getting your DID info from voip.ms, contact app developer", delegate: self, cancelButtonTitle: "Ok")
                alert.show()
//            })
        }
       
        
        
    }
    
    
    
    func skipToMainListVC() {
        let backgroundMOC : NSManagedObjectContext = CoreDataStack().managedObjectContext!
        if let currentUser = CoreUser.currentUser(backgroundMOC) {
            currentUser.initialLogon = 0
            currentUser.messagesLoaded = 1
            CoreUser.updateInManagedObjectContext(backgroundMOC, coreUser: currentUser)
            self.performSegueWithIdentifier("segueToMessages", sender: self)
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
            self.dismissViewControllerAnimated(true, completion: nil)
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
