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
//        startTimer()
        if let dids = CoreDID.getDIDs(moc) {
            if let str = dids.filter({$0.currentlySelected.boolValue == true}).first {
                if let currentUser = CoreUser.currentUser(self.moc) {
                    Message.getMessagesFromAPI(false, moc: moc, from: str.registeredOn.strippedDateFromString(), completionHandler: { (responseObject,
                        error) -> () in
                        println("done")
                        currentUser.initialLogon = 0
                        currentUser.messagesLoaded = 1
                        CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
                        self.activityIndicator.stopAnimating()
                        self.performSegueWithIdentifier("segueToMessages", sender: self)
                    })
                }
            }
        }
    }
    
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "updateMessageCounter:", userInfo: nil, repeats: true)
        }
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
