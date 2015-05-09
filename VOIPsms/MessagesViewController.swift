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
        startTimer()
       
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
//        self.activityIndicator.center=self.view.center;
        self.activityIndicator.startAnimating()
        viewSetup()
        timer.invalidate()
        startTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        var btnDID = UIButton(frame: CGRectMake(0, 0, 100, 40))
        btnDID.setTitle("All Messages (filter)", forState: UIControlState.Normal)
        btnDID.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
        btnDID.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        self.navigationController?.navigationBar.topItem?.titleView = btnDID
        
    }
    
    func viewSetup() {

        if CoreUser.userExists(moc) {
            CoreDID.createOrUpdateDID(self.moc)
            if let didArr = CoreDID.getDIDs(moc) {
                did = didArr[0].did
            }
            
            self.tableView.reloadData()

            CoreContact.getContacts(moc, did: did, completionHandler: { (responseObject, error) -> () in
                self.contacts = responseObject
                self.activityIndicator.stopAnimating()
            })

        } else {
            self.activityIndicator.stopAnimating()
        }
        self.tableView.reloadData()
    }
    
    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
    }
    
    func timerDidFire(sender: NSTimer) {
        if CoreUser.userExists(moc) {
            Message.getMessagesFromAPI(self.moc, completionHandler: { (responseObject, error) -> () in
                if responseObject.count > 0 {
                    CoreDID.createOrUpdateDID(self.moc)
                    CoreContact.getContacts(self.moc, did: self.did, completionHandler: { (responseObject, error) -> () in
                        self.contacts = responseObject
                        let indexSet = NSIndexSet(index: 0)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
                        })

                        self.activityIndicator.stopAnimating()
                    })
                } else {
                    println("no messages yet")
                }
            })
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
        
        //if not and existing contact from contacts - format
        cell.textLabel?.text = CoreContact.getFormattedPhoneNumber(contact.contactId) as String
        //if existing contact : cell... = contact.full_name
        
        

        
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
//        contacts = CoreContact.getContacts(moc, did: nil)
        CoreContact.getContacts(moc, did: did) { (responseObject, error) -> () in
            self.contacts = responseObject
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showMessagesSegue") {
            
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            let path = self.tableView.indexPathForSelectedRow()

            var contactId = self.contacts[path!.row].contactId
            
            var messages = CoreContact.getMsgsByContact(moc, contactId: contactId)
            detailSegue.titleText = CoreContact.getFormattedPhoneNumber(contactId) as String
            detailSegue.contactId = contactId
            timer.invalidate()
//            detailSegue.messages = messages
            
            
        }
        
       
    }
    

}
