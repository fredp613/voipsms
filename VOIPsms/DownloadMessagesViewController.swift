//
//  DownloadMessagesViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-27.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData


class DownloadMessagesViewController: UIViewController {

    @IBOutlet weak var lblCountHeader: UILabel!
    @IBOutlet weak var lblCount: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var timer : NSTimer = NSTimer()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lblCountHeader.hidden = true
        self.activityIndicator.startAnimating()
//        getMessages()

    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        getMessages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Custom Methods
    func getMessages() {
        if let dids = CoreDID.getDIDs(moc) {
            if let str = dids.filter({$0.currentlySelected.boolValue == true}).first {
                if let currentUser = CoreUser.currentUser(self.moc) {
                    Message.getMessagesFromAPI(false, moc: moc, from: str.registeredOn.strippedDateFromString(), completionHandler: { (responseObject,
                        error) -> () in
                    
                        if error == nil {
                           
                            if let contacts = CoreContact.getAllContacts(self.moc) {
                                for c in contacts {
                                    if let lastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: nil) {
                                        var formatter1: NSDateFormatter = NSDateFormatter()
                                        formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                                        let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
                                        c.lastModified = parsedDate
                                        CoreContact.updateContactInMOC(self.moc)
                                    }
                                }
                            }
                            if Contact().checkAccess() {
                                Contact().syncAddressBook1()
                            }
                            
                            println("done")
                            currentUser.initialLogon = 0
                            currentUser.messagesLoaded = 1
                            CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
                            self.activityIndicator.stopAnimating()
                            self.performSegueWithIdentifier("segueToMessages", sender: self)
                        } else {
                            println(error)
                            self.showErrorController()
                            //here have the try again button or UIViewController
                        }
                    })
                }
            }
        }
    }
    
    func showErrorController() {
        var alertController = UIAlertController(title: "Network Error", message: "We are having trouble reaching the voip.ms servers, click Ok to try again or No to cancel to try again later", preferredStyle: .Alert)
        
        var okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            println("pressed")
            self.getMessages()
        }
        var cancelAction = UIAlertAction(title: "No, cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            println("cancelled")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func updateMessageCounter(sender: NSTimer) {
//        println("message starting")
//        let moc1 = CoreDataStack().managedObjectContext!
//        println(CoreMessage.getMessages(moc1, ascending: false).count)


//        if messageCount > 0 {
//            lblCountHeader.hidden = false
//            lblCount.text = String(messageCount)
//        }
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
