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

@objc protocol MessageViewDelegate {
     optional func updateMessagesTableView()
    optional func triggerSegue(contact: String)
}

struct ContactStruct {
    var contactName = String()
    var contactId = String()
    var lastMsgDate = String()
    var lastMsg = String()
    var lastMsgType = NSNumber()
    var lastMsgFlag = String()
    var did = String()
}


class MessagesViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, MessageViewDelegate {

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var newMessageButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTextField: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var contacts : [CoreContact] = [CoreContact]()
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var maskView : UIView = UIView()
    var timer : NSTimer = NSTimer()
    var did : String = String()
    var didView : UIPickerView = UIPickerView()
    var titleBtn : UIButton = UIButton()
    var contactForSegue = String()
    var contactsArray = [ContactStruct]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        if self.searchBar.text != "" {
            timer.invalidate()
        }
        
        checkAllPermissions()
        
    }
    
    func checkAllPermissions() {
        
        if let currentUser = CoreUser.currentUser(moc) {
            if currentUser.initialLogon.boolValue == false {
                if Contact().checkAccess() == true {
                    println("has access")
                    askPermissionForNotifications()
                } else {
                    var alertController = UIAlertController(title: "No contact access", message: "In order to link to your messages to your contacts, voip.ms sms requires access to your contacts. You will need to grant access for this app to sync with your phone contacts in your phone settings", preferredStyle: .Alert)
                    
                    var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                        println("pressed")
                        self.askPermissionForNotifications()
                    }
                    var cancelAction = UIAlertAction(title: "No, do not sync my contacts", style: UIAlertActionStyle.Cancel) {
                        UIAlertAction in
                        println("cancelled")
                    }
                    alertController.addAction(okAction)
                    alertController.addAction(cancelAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                }

            }
        }
    }
 
    
    func askPermissionForNotifications() -> Bool {
        var application = UIApplication.sharedApplication()
        if application.respondsToSelector("isRegisteredForRemoteNotifications")
        {
           
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Badge | .Sound | .Alert, categories: nil))
            let grantSettings = application.currentUserNotificationSettings()
            if grantSettings.types == UIUserNotificationType.None {
                println("not registered for local notifications")
                var alertController = UIAlertController(title: "Notifications", message: "This app has not been granted permission to send you notifications - if you want to recieve notifications when a user sends you a message please go into your phone settings and allow notifications for this app", preferredStyle: .Alert)
                var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                    println("pressed")
                    
                }
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                println("registered for local notifications")
                
            }
            return true
        }else{
            // iOS < 8 Notifications
            application.registerForRemoteNotificationTypes(.Badge | .Sound | .Alert)
        }
        return false
    }
    
    func updateMessagesTableView() {
        println("delegate called")
        viewSetup(true)
    }
    
    func triggerSegue(contact: String) {
        self.contactForSegue = contact
        self.performSegueWithIdentifier("showMessagesSegue", sender: self)
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
                       
        titleBtn = UIButton(frame: CGRectMake(0, 0, 100, 40))
        if let selectedDID = CoreDID.getSelectedDID(moc) {
            self.did = selectedDID.did
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            titleBtn.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
            titleBtn.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.navigationController?.navigationBar.topItem?.titleView = titleBtn
        }
       
        if CoreUser.userExists(moc) {
            
            let currentUser = CoreUser.currentUser(moc)
            let pwd = KeyChainHelper.retrieveForKey(currentUser!.email)
            
            if currentUser?.remember == false {
                performSegueWithIdentifier("showLoginSegue", sender: self)
            }
            
            CoreUser.authenticate(moc, email: currentUser!.email, password: pwd!, completionHandler: { (success) -> Void in
                if success == false || currentUser?.remember == false {
                    self.performSegueWithIdentifier("showLoginSegue", sender: self)
                }
            })
            
        } else {
            performSegueWithIdentifier("showLoginSegue", sender: self)
        }
        
        viewSetup(false)
        startTimer()
        
        if self.searchBar.text != "" {
            self.search(self.searchBar.text)
            timer.invalidate()
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)

    }
    
    
    func viewSetup(fromSegue: Bool) {
        
        
        
        if CoreUser.userExists(moc) {
            if self.contacts.count == 0 {
                if self.activityIndicator != nil {
                    self.activityIndicator.startAnimating()
                }
            }
            var searchTerm = ""
            if self.searchBar != nil {
                searchTerm = self.searchBar.text
            }
            
            
            CoreContact.getContacts(moc, did: did, dst: searchTerm, name: searchTerm, message: searchTerm, completionHandler: { (responseObject, error) -> () in
                self.contacts = responseObject as! [CoreContact]
                self.contactsArray = [ContactStruct]()
                for c in self.contacts {
                    var contact = ContactStruct()
                    contact.contactId = c.contactId
                    
                    if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
                        let d = contactLastMessage.date
                        contact.lastMsgDate = d
                        contact.lastMsg = contactLastMessage.message
                        contact.lastMsgType = contactLastMessage.type
                        contact.lastMsgFlag = contactLastMessage.flag
                        contact.did = self.did
                    }
                    self.contactsArray.append(contact)

                }
                
                var newMessageCount = CoreMessage.getMessages(self.moc, ascending: false).count
                let indexSet = NSIndexSet(index: 0)
                if self.tableView != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if !fromSegue {
                            self.contactsArray.sort({$0.lastMsgDate > $1.lastMsgDate})
                            self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    })
                }
//                CoreContact.findByName(self.moc, searchTerm: searchTerm, existingContacts: self.contacts, completionHandler: { (contacts) -> () in
//                        self.contacts = contacts!
//                        self.contactsArray = [ContactStruct]()
//                        for c in self.contacts {
//                            var contact = ContactStruct()
//                            contact.contactId = c.contactId
//                            
//                            if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
//                                let d = contactLastMessage.date
//                                contact.lastMsgDate = d
//                                contact.lastMsg = contactLastMessage.message
//                                contact.lastMsgType = contactLastMessage.type
//                                contact.lastMsgFlag = contactLastMessage.flag
//                                contact.did = self.did
//                            }
//                                self.contactsArray.append(contact)
//                        }
//
//                        var newMessageCount = CoreMessage.getMessages(self.moc, ascending: false).count
//                        let indexSet = NSIndexSet(index: 0)
//                        if self.tableView != nil {
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                if !fromSegue {
//                                    self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
//                                }
//                            })
//                        }
//                })
            })
        }

    }
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        } else {
           let alert = UIAlertView(title: "Netword Error", message: "You need to be connected to the network to be able to send and receive messages", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
        }

    }
    
    func timerDidFire(sender: NSTimer) {

        var initialMessageCount = CoreMessage.getMessages(moc, ascending: false).count
        if CoreUser.userExists(moc) {
            if let str = CoreDID.getSelectedDID(moc) {
                let fromStr = CoreMessage.getLastMsgByDID(moc, did: did)?.date.strippedDateFromString()
                if fromStr == nil && self.contacts.count > 0 {
                    self.activityIndicator.startAnimating()
                }
//                println("wefs")
                Message.getMessagesFromAPI(false, moc: self.moc, from: fromStr, completionHandler: { (responseObject, error) -> () in
                    if responseObject.count > 0 {

                        CoreContact.getContacts(self.moc, did: self.did, dst: self.searchBar.text, name: self.searchBar.text, message: self.searchBar.text, completionHandler: { (responseObject, error) -> () in
                            self.contacts = responseObject as! [CoreContact]
                            

                            var newMessageCount = CoreMessage.getMessages(self.moc, ascending: false).count
                            var initialLogon = false
                            if let cu = CoreUser.currentUser(self.moc) {
                                if cu.initialLogon == true {
                                    initialLogon = true
                                }
                            }
                            if (initialMessageCount < newMessageCount) || initialLogon {
                                println("hey")
                                self.contactsArray = [ContactStruct]()
                                for c in self.contacts {
                                    var contact = ContactStruct()
                                    contact.contactId = c.contactId
                                    if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
                                        let d = contactLastMessage.date
                                        contact.lastMsgDate = d
                                        contact.lastMsg = contactLastMessage.message
                                        contact.lastMsgType = contactLastMessage.type
                                        contact.lastMsgFlag = contactLastMessage.flag
                                        contact.did = self.did
                                    }
                                    self.contactsArray.append(contact)

                                }
                                
                                self.contactsArray.sort({$0.lastMsgDate > $1.lastMsgDate})
                                let indexSet = NSIndexSet(index: 0)
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
                                })
                            }
                            if let currentUser = CoreUser.currentUser(self.moc) {
                                if currentUser.initialLogon.boolValue {
                                    CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
                                }
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.activityIndicator.stopAnimating()
                            })
                            
                           
                        })
                        
                    } else {
                        println("no messages yet")
                    }
                })
            }
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
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0: return self.contactsArray.count
            case 1: return self.contactsArray.count
            default: fatalError("unknown section")
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        var contact = self.contactsArray[indexPath.row]
        var contactName = String()
        
        if Contact().checkAccess() {
            Contact().getContactsDict { (contacts) -> () in
                let contStr = contact.contactId as String
                if contacts[contact.contactId] != nil {
                    cell.textLabel?.text = contacts[contact.contactId]
                } else {
                    cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
                }
            }
        } else {
//            if (contact.contactId.toInt() != nil) {
                cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
//            } else {
//                cell.textLabel?.text = contact.contactId
//            }
        }
        
        

        
        cell.detailTextLabel?.text = "\(contact.lastMsg)"
        if contact.lastMsgType == true || contact.lastMsgType == 1 {
            if contact.lastMsgFlag == message_status.PENDING.rawValue {
                cell.detailTextLabel?.textColor = UIColor.blueColor()
            } else {
                cell.detailTextLabel?.textColor = UIColor.blackColor()
            }
        } else {
            cell.detailTextLabel?.textColor = UIColor.blackColor()
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPth: NSIndexPath) -> Bool {
        return true
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.timer.invalidate()
        
        if editingStyle == UITableViewCellEditingStyle.Delete {

            let contactId = contacts[indexPath.row].contactId
            var ids = CoreContact.getMsgsByContact(moc, contactId: contactId, did: self.did).map {$0.id}

            CoreMessage.deleteAllMessagesFromContact(moc, contactId: contactId, did: self.did, completionHandler: { (responseObject, error) -> () in
                
                CoreContact.getContacts(self.moc, did: self.did, dst: self.searchBar.text, name: self.searchBar.text, message:
                    self.searchBar.text, completionHandler: { (responseObject, error) -> () in
                        self.contacts = responseObject as! [CoreContact]
                        self.contactsArray = [ContactStruct]()
                        for c in self.contacts {
                            var contact = ContactStruct()
                            contact.contactId = c.contactId
                            
                            if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
                                let d = contactLastMessage.date
                                contact.lastMsgDate = d
                                contact.lastMsg = contactLastMessage.message
                                contact.lastMsgType = contactLastMessage.type
                                contact.lastMsgFlag = contactLastMessage.flag
                                contact.did = self.did
                            }
                            self.contactsArray.append(contact)
                        }
                        self.tableView.beginUpdates()
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        self.tableView.endUpdates()
                        
//                        CoreContact.findByName(self.moc, searchTerm: "", existingContacts: self.contacts, completionHandler: { (contacts) -> () in
//                            self.contacts = responseObject as! [CoreContact]
//                            self.contactsArray = [ContactStruct]()
//                            for c in self.contacts {
//                                var contact = ContactStruct()
//                                contact.contactId = c.contactId
//                                
//                                if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
//                                    let d = contactLastMessage.date
//                                    contact.lastMsgDate = d
//                                    contact.lastMsg = contactLastMessage.message
//                                    contact.lastMsgType = contactLastMessage.type
//                                    contact.lastMsgFlag = contactLastMessage.flag
//                                    contact.did = self.did
//                                }
//                                self.contactsArray.append(contact)
//                            }
//                            self.tableView.beginUpdates()
//                            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
//                            self.tableView.endUpdates()
////                            self.startTimer()
//
//                        })
                })

                //you may want to get rid of this
                Message.deleteMessagesFromAPI(ids, completionHandler: { (responseObject, error) -> () in
                    if responseObject {
                        println("something went right :)")
                    } else {
                        println("something went wrong")
                    }
                })
            })
        }
        self.contactsArray.sort({$0.lastMsgDate > $1.lastMsgDate})
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            self.performSegueWithIdentifier("showMessagesSegue", sender: self)
    }
    
    //MARK: - Button Events
    func titleClicked(sender: UIButton) {

        didView.removeFromSuperview()
        
        didView = UIPickerView(frame: CGRectMake(0, 0, self.tableView.frame.size.width / 2, self.tableView.frame.size.height / 2))
        didView.center = self.view.center
        didView.backgroundColor = UIColor.whiteColor()
        didView.layer.cornerRadius = 10
        didView.layer.borderColor = UIColor.lightGrayColor().CGColor
        didView.layer.borderWidth = 1.0
        didView.delegate = self
        didView.dataSource = self

        var didArr = [String]()
        if let coreDids = CoreDID.getDIDs(self.moc) {
//            coreDids.filter() { $0.did == self.did }
            for c in coreDids {
                didArr.append(c.did)
            }
        }
        let currentDIDIndex = find(didArr, self.did)
        didView.selectRow(currentDIDIndex!, inComponent: 0, animated: false)
        drawMaskView()
        self.view.addSubview(didView)

    }
    
    @IBAction func logoutWasPressed(sender: AnyObject) {
        let currentUser = CoreUser.currentUser(moc)
        CoreUser.logoutUser(moc, coreUser: currentUser!)
        self.performSegueWithIdentifier("showLoginSegue", sender: self)
    }
    
    @IBAction func newMessageWasPressed(sender: AnyObject) {
    }
    
    //MARK: - PickerView delegate methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CoreDID.getDIDs(self.moc)!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let formattedDID = CoreDID.getDIDs(self.moc)![row].did.northAmericanPhoneNumberFormat()
        return formattedDID
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if let dids = CoreDID.getDIDs(self.moc) {
            self.did = dids[row].did
            CoreDID.toggleSelected(moc, did: self.did)
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            viewSetup(false)
        }
        didView.removeFromSuperview()
        maskView.removeFromSuperview()
    }
    
    //MARK: - Searchbar delegate methods
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        clearSearch()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()
        didView.removeFromSuperview()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        drawMaskView()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if self.searchBar.text == "" || self.searchBar.text == nil {
            clearSearch()
        } else {
            self.search(searchText)
        }
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        if self.searchBar.text == "" || self.searchBar.text == nil {
            clearSearch()
        }
        return true
    }
    
    func drawMaskView() {
        maskView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y - 75, self.tableView.frame.width, self.tableView.frame.height)
        maskView.backgroundColor = UIColor(white: 0.98, alpha: 0.8)
        maskView.bounds = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.width, tableView.frame.height)//- (searchBar.frame.height * 2) - 60)
        maskView.center = self.tableView.center
        self.view.addSubview(maskView)
    }
    
    func clearSearch() {
        self.searchBar.text = ""
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()

        CoreContact.getContacts(moc, did: did, dst: nil, name: nil, message: nil) { (responseObject, error) -> () in
            CoreContact.findByName(self.moc, searchTerm: "", existingContacts: self.contacts, completionHandler: { (contacts) -> () in
                self.contacts = responseObject as! [CoreContact]
                self.contactsArray = [ContactStruct]()
                for c in self.contacts {
                    var contact = ContactStruct()
                    contact.contactId = c.contactId
                    
                    if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
                        let d = contactLastMessage.date
                        contact.lastMsgDate = d
                        contact.lastMsg = contactLastMessage.message
                        contact.lastMsgType = contactLastMessage.type
                        contact.lastMsgFlag = contactLastMessage.flag
                    }
                    self.contactsArray.append(contact)
                }
                self.contactsArray.sort({$0.lastMsgDate > $1.lastMsgDate})
                self.tableView.reloadData()
            })
        }
    }
    
    func search(searchTerm: String) {
        timer.invalidate()
        if count(searchTerm) > 0 {
            CoreContact.getContacts(moc, did: did, dst: searchTerm, name: searchTerm, message: searchTerm, completionHandler: { (responseObject, error) -> () in
                var contacts1 = responseObject as! [CoreContact]
                CoreContact.findByName(self.moc, searchTerm: searchTerm, existingContacts: contacts1, completionHandler: { (contacts) -> () in
                    if let contact = contacts {
                        self.contacts = contact
                        self.contactsArray = [ContactStruct]()
                        for c in self.contacts {
                            var contact = ContactStruct()
                            contact.contactId = c.contactId
                            
                            if let contactLastMessage = CoreContact.getLastMessageFromContact(self.moc, contactId: c.contactId, did: self.did) {
                                let d = contactLastMessage.date
                                contact.lastMsgDate = d
                                contact.lastMsg = contactLastMessage.message
                                contact.lastMsgType = contactLastMessage.type
                                contact.lastMsgFlag = contactLastMessage.flag
                            }
                            self.contactsArray.append(contact)
                        }
                        self.contactsArray.sort({$0.lastMsgDate > $1.lastMsgDate})
                        let indexSet = NSIndexSet(index: 0)
                        self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                })
            })
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if (segue.identifier == "showLoginSegue") {
            var loginVC = segue.destinationViewController as? ViewController
            loginVC?.delegate = self
        }
        
        if (segue.identifier == "showMessagesSegue") {
            self.searchBar.resignFirstResponder()
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                detailSegue.contactId = self.contactsArray[indexPath.row].contactId
            } else {
                detailSegue.contactId = self.contactForSegue
            }
            
            detailSegue.did = self.did
            timer.invalidate()
        }
        
        if segue.identifier == "newMessageSegue" {
            var newMsgVC = segue.destinationViewController as? NewMessageViewController
            newMsgVC?.delegate = self
        }
       
    }
    

}
