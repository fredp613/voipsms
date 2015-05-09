//
//  MessagesViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-16.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore

//protocol UpdateMessagesTableViewDelegate {
//    func updateMessagesTableView()
//}


class MessagesViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTextField: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var contacts : [CoreContact] = [CoreContact]()
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var currentDID : CoreDID!
    var maskView : UIView = UIView()
    var timer : NSTimer = NSTimer()
    var did : String = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        viewSetup()
    }

    func timerDidFire(sender: NSTimer) {
        if CoreUser.userExists(moc) {
            Message.getMessagesFromAPI(self.moc, completionHandler: { (responseObject, error) -> () in
                if responseObject.count > 0 {
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        CoreDID.createOrUpdateDID(self.moc)
                        self.contacts = CoreContact.getContacts(self.moc, did: self.did)
                        self.tableView.reloadData()
                        self.activityIndicator.stopAnimating()
//                    })
                } else {
                    println("no messages yet")
                }
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        var btnDID = UIButton(frame: CGRectMake(0, 0, 100, 40))
        btnDID.setTitle("All Messages (filter)", forState: UIControlState.Normal)
        btnDID.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
        btnDID.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        self.navigationController?.navigationBar.topItem?.titleView = btnDID
        viewSetup()
    }
    
    func viewSetup() {
        self.activityIndicator.center=self.view.center;
        if CoreUser.userExists(moc) {
            self.activityIndicator.startAnimating()
            CoreDID.createOrUpdateDID(self.moc)
            did = "6135021177"
            self.contacts = CoreContact.getContacts(self.moc, did: did)
            self.activityIndicator.stopAnimating()
        } else {
            self.activityIndicator.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell    
        var contact = self.contacts[indexPath.row]
        cell.textLabel?.text = contact.contactId
        
        
        if let lastMessage = CoreContact.getLastMessageFromContact(moc, contactId: contact.contactId) {
            cell.detailTextLabel?.text = "\(lastMessage.message)"
            if lastMessage.type == true || lastMessage.type == 1 {
                if lastMessage.flag == message_status.PENDING.rawValue {
                    cell.detailTextLabel?.textColor = UIColor.blueColor()
                } else {
                    cell.detailTextLabel?.textColor = UIColor.blackColor()
                }
            }

        }
        
        return cell

    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier("showMessagesSegue", sender: self)
//        })
    }
    
    //MARK: - Button Events
    func titleClicked(sender: UIButton) {
        println("clicked")
    }
    
    
    //MARK: - Searchbar delegate methods
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        clearSearch()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //add blocking view
        
        maskView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y - 75, self.tableView.frame.width, self.tableView.frame.height)
        maskView.backgroundColor = UIColor(white: 0.98, alpha: 0.8)
        maskView.bounds = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.width, tableView.frame.height - (searchBar.frame.height * 2) - 60) //CGRectMake(0, -150, self.tableView.frame.width, (self.view.frame.height -  350))
        self.view.addSubview(maskView)
    }
    
    func clearSearch() {
        self.searchBar.text = ""
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()
        contacts = CoreContact.getContacts(moc, did: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showMessagesSegue") {
            
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            let path = self.tableView.indexPathForSelectedRow()

            var contactId = self.contacts[path!.row].contactId
            
            var messages = CoreContact.getMsgsByContact(moc, contactId: contactId)
            detailSegue.titleText = CoreContact.currentContact(self.moc, contactId: contactId)!.contactId
            detailSegue.contactId = contactId
            timer.invalidate()
//            detailSegue.messages = messages
            
            
        }
        
       
    }
    

}
