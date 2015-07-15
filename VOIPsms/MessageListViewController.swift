//
//  MessageListViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

@objc protocol MessageListViewDelegate {
    optional func triggerSegue(contact: String, moc: NSManagedObjectContext)
    optional func updateMessagesTableView()
}

class MessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MessageListViewDelegate {
    
    @IBOutlet weak var btnNewMessage: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var maskView : UIView = UIView()
    var did : String = String()
    var titleBtn: UIButton = UIButton()
    var timer : NSTimer = NSTimer()
    var managedObjectContext : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var searchKeyword: String = String()
    var didView : UIPickerView = UIPickerView()
    var contactForSegue : String = String()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreContact")
        let primarySortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
        if let did = CoreDID.getSelectedDID(self.managedObjectContext) {
            self.did = did.did
            var contactIDs = CoreMessage.getMessagesByDID(self.managedObjectContext, did: did.did).map({$0.contactId})
            let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
            let contactPredicateDeleted = NSPredicate(format: "deletedContact == 0")
            let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [contactPredicate, contactPredicateDeleted])
            contactsFetchRequest.predicate = compoundPredicate
        }
        
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    lazy var messageFetchedResultsController: NSFetchedResultsController = {
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let primarySortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        if let did = CoreDID.getSelectedDID(self.managedObjectContext) {
            let msgDIDPredicate = NSPredicate(format: "did == %@", self.did)
            contactsFetchRequest.predicate = msgDIDPredicate
        }
        
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error)==false) {
            println("An error has occurred: \(error?.localizedDescription)")
        }
        
        if (messageFetchedResultsController.performFetch(&error)==false) {
            println("An error has occurred: \(error?.localizedDescription)")
        }
        
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            currentUser.initialLoad = true
            CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
        }
        
        self.btnNewMessage.layer.cornerRadius = self.btnNewMessage.frame.size.height / 2
        self.view.bringSubviewToFront(self.btnNewMessage)
        self.pokeFetchedResultsController()
        //        self.tableView.reloadData()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.pokeFetchedResultsController()
        titleBtn = UIButton(frame: CGRectMake(navigationController!.navigationBar.center.x, navigationController!.navigationBar.center.y, 100, 40))
        if let selectedDID = CoreDID.getSelectedDID(managedObjectContext) {
            self.did = selectedDID.did
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            titleBtn.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
            titleBtn.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.navigationController?.navigationBar.topItem?.titleView = titleBtn
        }
        
        if CoreUser.userExists(managedObjectContext) {
            let currentUser = CoreUser.currentUser(managedObjectContext)
            let pwd = KeyChainHelper.retrieveForKey(currentUser!.email)
            
            CoreUser.authenticate(managedObjectContext, email: currentUser!.email, password: pwd!, completionHandler: { (success, error) -> Void in
                if success == false || currentUser?.remember == false {
                    self.performSegueWithIdentifier("showLoginSegue", sender: self)
                } else {
                    if currentUser!.messagesLoaded.boolValue == false || currentUser!.messagesLoaded == 0 {
                        self.performSegueWithIdentifier("showDownloadMessagesSegue", sender: self)
                    } else {
                        self.startTimer()
                    }
                }
            })
            
        } else {
            performSegueWithIdentifier("showLoginSegue", sender: self)
        }
        
        
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        //        self.fetchedResultsController.delegate = nil
    }
    
    func checkAllPermissions() {
        
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            if currentUser.initialLogon.boolValue == true {
                if Contact().checkAccess() == true {
                    if currentUser.initialLoad.boolValue == true {
                        //                        self.askPermissionForNotifications()
                    }
                } else {
                    var alertController = UIAlertController(title: "No contact access", message: "In order to link to your messages to your contacts, voip.ms sms requires access to your contacts. You will need to grant access for this app to sync with your phone contacts in your phone settings", preferredStyle: .Alert)
                    
                    var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                        //                        self.askPermissionForNotifications()
                    }
                    var cancelAction = UIAlertAction(title: "No, do not sync my contacts", style: UIAlertActionStyle.Cancel) {
                        UIAlertAction in
                        //                        self.askPermissionForNotifications()
                    }
                    alertController.addAction(okAction)
                    alertController.addAction(cancelAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                }
                
            }
        }
    }
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func timerDidFire(sender: NSTimer) {
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        //        dispatch_async(backgroundQueue, { () -> Void in
        if let str = CoreDID.getSelectedDID(self.managedObjectContext) {
            if let cm = CoreMessage.getMessagesByDID(self.managedObjectContext, did: self.did).first {
                if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
                    let lastMessage = cm
                    var from = ""
                    from = lastMessage.date
                    Message.getMessagesFromAPI(false, moc: self.managedObjectContext, from: from.strippedDateFromString(), completionHandler: { (responseObject, error) -> () in
                        if currentUser.initialLogon.boolValue == true || currentUser.initialLoad.boolValue == true {
                            currentUser.initialLoad = 0
                            currentUser.initialLogon = 0
                            CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
                        }
                        self.pokeFetchedResultsController()
                    })
                }
                
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newMessageWasPressed(sender: AnyObject) {
        //        segueToNewMessage
        self.performSegueWithIdentifier("segueToNewMessage", sender: self)
    }
    
    
    //MARK: Core Data Delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if controller == fetchedResultsController {
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Delete:
                println("deleting")
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Update:
                println("updating contact")
                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            default:
                self.pokeFetchedResultsController()
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
//        self.pokeFetchedResultsController()
    }
    
    //MARK: table view delegates
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            //use the below for sections - look at sectionkeynamepath in the fetchedresultscontroller to create sections
            return sections.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        //
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("selected row")
        self.timer.invalidate()
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        let contact = fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        
        //        if let lastMessage = contact.messages.sortedArrayUsingDescriptors([sortDescriptor]).first! as? CoreMessage {
        if let lastMessage = CoreContact.getLastMessageFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did) {
            let message = lastMessage as CoreMessage
            cell.detailTextLabel?.text = "\(message.message) - \(contact.lastModified) - \(message.flag)"
            let font:UIFont? = UIFont(name: "Arial", size: 13.0)
            let dateStr = NSAttributedString(string: message.date.dateFormattedString(), attributes:
                [NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                    NSFontAttributeName: font!])
            let dateFrame = CGRectMake(cell.frame.origin.x, cell.detailTextLabel!.frame.origin.x, cell.frame.width - 30, cell.textLabel!.frame.height)
            let dateLbl = UILabel(frame: dateFrame)
            dateLbl.attributedText = dateStr
            dateLbl.textAlignment = NSTextAlignment.Right
            dateLbl.tag = 3
            if cell.contentView.viewWithTag(3) != nil {
                cell.contentView.viewWithTag(3)?.removeFromSuperview()
            }
            if message.type.boolValue == true {
                if message.flag != message_status.READ.rawValue {
                    var textCol = UIColor.blueColor()
                    cell.textLabel?.textColor = textCol
                    cell.detailTextLabel?.textColor = textCol
                    dateLbl.textColor = textCol
                } else {
                    var textCol = UIColor.blackColor()
                    cell.textLabel?.textColor = textCol
                    cell.detailTextLabel?.textColor = textCol
                }
            }
            cell.contentView.addSubview(dateLbl)
        }
        
        
        
        
        
        //        var messages = messageFetchedResultsController.fetchedObjects
        //        if let message = messages?.first as? CoreMessage {
        //            cell.detailTextLabel?.text = message.message
        //            let font:UIFont? = UIFont(name: "Arial", size: 13.0)
        //            let dateStr = NSAttributedString(string: message.date.dateFormattedString(), attributes:
        //                [NSForegroundColorAttributeName: UIColor.lightGrayColor(),
        //                    NSFontAttributeName: font!])
        //            let dateFrame = CGRectMake(cell.frame.origin.x, cell.detailTextLabel!.frame.origin.x, cell.frame.width - 30, cell.textLabel!.frame.height)
        //            let dateLbl = UILabel(frame: dateFrame)
        //            dateLbl.attributedText = dateStr
        //            dateLbl.textAlignment = NSTextAlignment.Right
        //            dateLbl.tag = 3
        //            if cell.contentView.viewWithTag(3) != nil {
        //                cell.contentView.viewWithTag(3)?.removeFromSuperview()
        //            }
        //            if message.type.boolValue == true {
        //                if message.flag != message_status.READ.rawValue {
        //                    var textCol = UIColor.blueColor()
        //                    cell.textLabel?.textColor = textCol
        //                    cell.detailTextLabel?.textColor = textCol
        //                    dateLbl.textColor = textCol
        //                }
        //            }
        //
        //            cell.contentView.addSubview(dateLbl)
        //
        //        }
        
        if contact.fullName != nil {
            cell.textLabel?.text = contact.fullName
        } else {
            cell.textLabel?.text = "\(contact.contactId.northAmericanPhoneNumberFormat())"  //.northAmericanPhoneNumberFormat()
        }
        
        
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPth: NSIndexPath) -> Bool {
        return true
    }
    
    
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        self.timer.invalidate()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            var contactId = String()
            var contact = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
            contactId = contact.contactId
            contact.deletedContact = 1
            CoreContact.updateContactInMOC(self.managedObjectContext)
            
//            self.pokeFetchedResultsController()
//            self.tableView.reloadData()
            
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, { () -> Void in

                
//                var messages = self.messageFetchedResultsController.fetchedObjects?.filter({$0.contactId == contactId}) as! [CoreMessage]
//                CoreMessage.deleteAllMessagesFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did, completionHandler: { (responseObject, error) -> () in
//                })
                
            })
            
            //            CoreMessage.deleteAllMessagesFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did, completionHandler: { (responseObject, error) -> () in
            //                self.pokeFetchedResultsController()
            //            })
            
        }
        self.startTimer()
    }
    
    
    //MARK: - PickerView delegate methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CoreDID.getDIDs(self.managedObjectContext)!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let formattedDID = CoreDID.getDIDs(self.managedObjectContext)![row].did.northAmericanPhoneNumberFormat()
        return formattedDID
    }
    
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //        self.tableView.reloadData()
        if let dids = CoreDID.getDIDs(self.managedObjectContext) {
            self.did = dids[row].did
            CoreDID.toggleSelected(self.managedObjectContext, did: dids[row].did)
            
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            if let newDID = CoreDID.getSelectedDID(self.managedObjectContext) {
                self.did = newDID.did
                
                self.pokeFetchedResultsController()
                if self.fetchedResultsController.fetchedObjects?.count > 0 {
                    for c in self.fetchedResultsController.fetchedObjects as! [CoreContact] {
                        if let lastMessage = CoreContact.getLastMessageFromContact(self.managedObjectContext, contactId: c.contactId, did: self.did) {
                            var formatter1: NSDateFormatter = NSDateFormatter()
                            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                            let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
                            c.lastModified = parsedDate
                            CoreContact.updateContactInMOC(self.managedObjectContext)
                        }
                    }
                }
                
            }
        }
        maskView.removeFromSuperview()
        didView.removeFromSuperview()
        self.tableView.reloadData()
        startTimer()
    }
    
    
    //MARK: Search Bar Delegate Methods
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchKeyword = searchText
        search()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        clearSearch()
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    //MARK: Custom Methods
    
    func search() {
        if self.searchBar.text != "" {
            
            var messagePredicate : NSPredicate?
            if let messages = CoreMessage.getMessagesByString(managedObjectContext, message: self.searchBar.text, did: self.did) {
                if messages.count > 0 {
                    messagePredicate = NSPredicate(format: "contactId IN %@", messages.map({$0.contactId}))
                }
            }
            let firstPredicate = NSPredicate(format: "contactId contains[cd] %@", self.searchKeyword)
            let secondPredicate = NSPredicate(format: "fullName contains[cd] %@", self.searchKeyword)
            if let messagePredicate = messagePredicate {
                let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [firstPredicate, secondPredicate, messagePredicate])
                fetchedResultsController.fetchRequest.predicate = compoundPredicate
            } else {
                let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [firstPredicate, secondPredicate])
                fetchedResultsController.fetchRequest.predicate = compoundPredicate
            }
            
            self.fetchedResultsController.performFetch(nil)
            tableView.reloadData()
        } else {
            clearSearch()
        }
    }
    
    func clearSearch() {
        self.pokeFetchedResultsController()
    }
    
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
        if let coreDids = CoreDID.getDIDs(self.managedObjectContext) {
            for c in coreDids {
                didArr.append(c.did)
            }
        }
        let currentDIDIndex = find(didArr, self.did)
        didView.selectRow(currentDIDIndex!, inComponent: 0, animated: false)
        drawMaskView()
        self.view.addSubview(didView)
        timer.invalidate()
        
    }
    
    func drawMaskView() {
        maskView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y - 75, self.tableView.frame.width, self.tableView.frame.height)
        maskView.backgroundColor = UIColor(white: 0.98, alpha: 0.8)
        maskView.bounds = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.width, tableView.frame.height)//- (searchBar.frame.height * 2) - 60)
        maskView.center = self.tableView.center
        self.view.addSubview(maskView)
    }
    
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()
        didView.removeFromSuperview()
        startTimer()
    }
    
    func segueToNewMessage(sender: UIButton) {
        self.performSegueWithIdentifier("segueToNewMessage", sender: sender)
    }
    
    func pokeFetchedResultsController() {
        fetchedResultsController.fetchRequest.sortDescriptors = nil
        fetchedResultsController.fetchRequest.predicate = nil
        let primarySortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        fetchedResultsController.fetchRequest.sortDescriptors = [primarySortDescriptor]
        if let did = CoreDID.getSelectedDID(self.managedObjectContext) {
            self.did = did.did
            var contactIDs = CoreMessage.getMessagesByDID(self.managedObjectContext, did: did.did).map({$0.contactId})
            let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
            let contactPredicateDeleted = NSPredicate(format: "deletedContact == 0")
            let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [contactPredicate, contactPredicateDeleted])
            fetchedResultsController.fetchRequest.predicate = compoundPredicate
        }
        fetchedResultsController.performFetch(nil)
        self.tableView.reloadData()
    }
    
    
    //MARK: Class Delegate Methods
    
    func triggerSegue(contact: String, moc: NSManagedObjectContext) {
        self.contactForSegue = contact
        self.managedObjectContext = moc
//        self.pokeFetchedResultsController()
        self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
    }
    
    func updateMessagesTableView() {
        println("delegate called")
//        self.pokeFetchedResultsController()
//        self.tableView.reloadData()
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //        self.pokeFetchedResultsController()
        
        timer.invalidate()
        if (segue.identifier == "showMessageDetailSegue") {
            self.searchBar.resignFirstResponder()
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                var contact: CoreContact = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
                detailSegue.contactId = contact.contactId as String
                if let lastMessage = CoreContact.getLastMessageFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did) {
                    var formatter1: NSDateFormatter = NSDateFormatter()
                    formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    let parsedDate: NSDate = formatter1.dateFromString(lastMessage.date)!
                    contact.lastModified = parsedDate
                    CoreContact.updateContactInMOC(self.managedObjectContext)
                    if lastMessage.type.boolValue == true {
                        lastMessage.flag = message_status.READ.rawValue
                        CoreMessage.updateInManagedObjectContext(self.managedObjectContext, coreMessage: lastMessage)
                    } else if (lastMessage.id != "") {
                        lastMessage.flag = message_status.DELIVERED.rawValue
                        CoreMessage.updateInManagedObjectContext(self.managedObjectContext, coreMessage: lastMessage)
                    }
                }
                
                
            } else {
                detailSegue.contactId = self.contactForSegue
            }
            
            if let selectedDID = CoreDID.getSelectedDID(self.managedObjectContext) {
                self.did = selectedDID.did
            }
            detailSegue.did = self.did
            detailSegue.moc = self.managedObjectContext
            detailSegue.delegate = self
            
        }
        
        if segue.identifier == "segueToNewMessage" {
            var newMsgVC = segue.destinationViewController as? NewMessageViewController
            newMsgVC?.did = self.did
            newMsgVC?.delegate = self
            newMsgVC?.moc = self.managedObjectContext
        }
        
    }
    
    
}
