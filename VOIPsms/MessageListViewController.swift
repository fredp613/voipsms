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
    var searchKeyword: String = String()
    var didView : UIPickerView = UIPickerView()
    var contactForSegue : String = String()
    var fromClosedState : Bool = false
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).moc
//    let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)

    
    lazy var fetchedResultsController: NSFetchedResultsController = {
      
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreContact")
        let primarySortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
//        if let did = CoreDID.getSelectedDID(self.managedObjectContext) {
//            self.did = did.did
//            var contactIDs = CoreMessage.getMessagesByDID(self.managedObjectContext, did: did.did).map({$0.contactId})
//            let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
//            let contactPredicateDeleted = NSPredicate(format: "deletedContact == 0")
//            let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [contactPredicate, contactPredicateDeleted])
//            contactsFetchRequest.predicate = compoundPredicate
//        }
        
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
//        var error: NSError? = nil
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch {
            print("an error has occurred: \(error)")
        }
        
//        privateMOC.parentContext = managedObjectContext
        
        //refresh stuff
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            currentUser.initialLoad = true
            CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
            
            //refreshContacts
            let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
//            appDel.refreshContacts(privateMOC)
            appDel.refreshDeviceTokenOnServer(currentUser)
            
        }
        
        self.btnNewMessage.layer.cornerRadius = self.btnNewMessage.frame.size.height / 2
        self.view.bringSubviewToFront(self.btnNewMessage)
//        self.pokeFetchedResultsController()
        let identifier = UIDevice.currentDevice().identifierForVendor!.UUIDString
        print(identifier)
        

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageListViewController.handlePushNotification(_:)), name: "appRestorePush", object: nil)
        
    }
    
    func handlePushNotification(notification: NSNotification) {
        print("received a push notification - i'm in the list controller")
        print(notification.userInfo)

        if let did = notification.userInfo?["did"] as? String {
            if let contact = notification.userInfo?["contact"] as? String {
                self.contactForSegue = contact
                self.did = did
                
                self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
            }
        }
        
    }
    func handlePushNotification1() {
        self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
    }
    
    func togglePushToServer() {
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            
            let alertController = UIAlertController(title: "Activate Push Notifications", message: "**NOTE: Make sure that notifications are on for this app in your phone's setting**. Do you want to allow this app to send you push notifications?", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories: nil)
                
                UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                UIApplication.sharedApplication().registerForRemoteNotifications()
                    appDel.refreshDeviceTokenOnServer(currentUser)
                    self.navigationItem.rightBarButtonItem = nil
            }
            let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel) {
                UIAlertAction in
                
            }
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)

        }

        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.pokeFetchedResultsController()
        titleBtn = UIButton(frame: CGRectMake(navigationController!.navigationBar.center.x, navigationController!.navigationBar.center.y, 100, 40))
        if let selectedDID = CoreDID.getSelectedDID(managedObjectContext) {
            self.did = selectedDID.did
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            titleBtn.addTarget(self, action: #selector(MessageListViewController.titleClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            titleBtn.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.navigationController?.navigationBar.topItem?.titleView = titleBtn
        }
        
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            if currentUser.notificationsFlag.boolValue == false {
                let button = UIButton(type: UIButtonType.Custom)
                let image = UIImage(named: "push.png")
                button.setImage(image, forState: UIControlState.Normal)
                button.addTarget(self, action:#selector(MessageListViewController.togglePushToServer), forControlEvents: UIControlEvents.TouchUpInside)
                button.frame=CGRectMake(0, 0, (image?.size.height)!, (image?.size.width)!)
                let barButton = UIBarButtonItem(customView: button)
                self.navigationItem.rightBarButtonItem = barButton

            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
      
        if CoreUser.userExists(managedObjectContext) {
            let currentUser = CoreUser.currentUser(managedObjectContext)
            let pwd = KeyChainHelper.retrieveForKey(currentUser!.email)
            
            CoreUser.authenticate(managedObjectContext, email: currentUser!.email, password: pwd!, completionHandler: { (success, error, status) -> Void in
                if success == false || currentUser?.remember == false {
                    self.performSegueWithIdentifier("showLoginSegue", sender: self)
                } else {
                    if currentUser!.messagesLoaded.boolValue == false || currentUser!.messagesLoaded.boolValue == false {
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
                    let alertController = UIAlertController(title: "No contact access", message: "In order to link to your messages to your contacts, voip.ms sms requires access to your contacts. You will need to grant access for this app to sync with your phone contacts in your phone settings", preferredStyle: .Alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                        //                        self.askPermissionForNotifications()
                    }
                    let cancelAction = UIAlertAction(title: "No, do not sync my contacts", style: UIAlertActionStyle.Cancel) {
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
        var time = NSTimeInterval()
        if Reachability.isConnectedToNetwork() {
            if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
                time = 45
                print("registered")
            } else {
                time = 5
                print("no registered")
            }
            timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: #selector(MessageListViewController.timerDidFire(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func timerDidFire(sender: NSTimer) {

        if let cu = CoreUser.currentUser(self.managedObjectContext) {
            if cu.notificationLoad == 1 || cu.notificationLoad.boolValue {
                if let nc = cu.notificationContact  {
                    if let _ = CoreContact.currentContact(self.managedObjectContext, contactId: nc) {
                        self.contactForSegue = nc
                        //deleted contact
                    } else {
                        if let _ = CoreContact.createInManagedObjectContext(self.managedObjectContext, contactId: nc, lastModified: nil) {
                            self.contactForSegue = nc
                        }
                    }
                    self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
                }
            }
        }
        
            if let did = CoreDID.getSelectedDID(self.managedObjectContext) {
                
                if let cm = CoreMessage.getMessagesByDID(self.managedObjectContext, did: did.did).first {
                    
                    if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
                        let lastMessage = cm
                        var from = ""
                        from = lastMessage.date
                        Message.getMessagesFromAPI(false, fromList: true, moc: self.managedObjectContext, from: from.strippedDateFromString(), completionHandler: { (responseObject, error) -> () in
                            
                            if currentUser.initialLogon.boolValue == true || currentUser.initialLoad.boolValue == true {
                                currentUser.initialLoad = 0
                                currentUser.initialLogon = 0
                                CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
                            }
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
        //here maybe activate spinner
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if controller == fetchedResultsController {
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Delete:
                print("deleting contact")
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Update:
                print("updating contact")
//                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
//                self.tableView.reloadData()
            default:
                self.pokeFetchedResultsController()
            }
        }
    }

    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
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
       
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            print("------------------------------")
            let currentSection = sections[section]
            print(currentSection.numberOfObjects)
            return currentSection.numberOfObjects
        } else {
            print("hey")
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected row")
        self.timer.invalidate()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        let contact = fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
        print("hi")
        if let lastMessage = CoreContact.getLastMessageFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did) {
            let message = lastMessage as CoreMessage
            let text2 = message.message
            if message.flag == message_status.PENDING.rawValue {
                cell.detailTextLabel?.text = "\(text2) sending..."
            } else {
                cell.detailTextLabel?.text = "\(text2)"
            }

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
            var textCol = UIColor()
            if message.type.boolValue == true || message.type == 1 {
                if message.flag != message_status.READ.rawValue {
                    textCol = UIColor.blueColor()
                    dateLbl.textColor = textCol
                } else {
                    textCol = UIColor.blackColor()
                    dateLbl.textColor = UIColor.lightGrayColor()
                }
                
                cell.textLabel?.textColor = textCol
                cell.detailTextLabel?.textColor = textCol
            } else {
                //default light gray and text colors
                cell.textLabel?.textColor = UIColor.blackColor()
                cell.detailTextLabel?.textColor = UIColor.blackColor()
            }

            cell.contentView.addSubview(dateLbl)
        }
        

        if contact.fullName != nil {
            cell.textLabel?.text = contact.fullName.truncatedString()
            print("what")
            
        } else {
            cell.textLabel?.text = "asfsdf"
            cell.textLabel?.text = "\(contact.contactId.northAmericanPhoneNumberFormat())".truncatedString()
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
            
            let contact = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
            contact.deletedContact = 1
            CoreContact.updateContactInMOC(self.managedObjectContext)
            
//            self.pokeFetchedResultsController()
//            self.tableView.reloadData()
            
//            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//            dispatch_async(backgroundQueue, { () -> Void in
                let privateMocDel : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
                privateMocDel.parentContext = self.managedObjectContext
                privateMocDel.performBlock({ () -> Void in
                    CoreMessage.deleteAllMessagesFromContact(privateMocDel, contactId: contact.contactId, did: self.did, completionHandler: { (responseObject, error) -> () in
                    })
                })
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
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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
                            let formatter1: NSDateFormatter = NSDateFormatter()
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
            if let messages = CoreMessage.getMessagesByString(managedObjectContext, message: self.searchBar.text!, did: self.did) {
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
            
            do {
                try self.fetchedResultsController.performFetch()
            } catch _ {
            }
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
        let currentDIDIndex = didArr.indexOf(self.did)
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
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
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
            let contactIDs = CoreMessage.getMessagesByDID(self.managedObjectContext, did: did.did).map({$0.contactId})
            let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
            let contactPredicateDeleted = NSPredicate(format: "deletedContact == 0")
            let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [contactPredicate, contactPredicateDeleted])
            fetchedResultsController.fetchRequest.predicate = compoundPredicate
        }
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
        }
        self.tableView.reloadData()
    }
    
    //MARK: Class Delegate Methods
    func triggerSegue(contact: String, moc: NSManagedObjectContext) {
        self.contactForSegue = contact
//        self.managedObjectContext = moc
//        self.pokeFetchedResultsController()
        self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
    }
    
    func updateMessagesTableView() {
        print("delegate called")
//        self.pokeFetchedResultsController()
//        self.tableView.reloadData()
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

            if (segue.identifier == "showMessageDetailSegue") {
              
            
            let detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
                
            if !fromClosedState {
                timer.invalidate()
                self.searchBar.resignFirstResponder()
                
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    let contact: CoreContact = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
                    detailSegue.contactId = contact.contactId as String
                    if let lastMessage = CoreContact.getLastMessageFromContact(self.managedObjectContext, contactId: contact.contactId, did: self.did) {
                        let formatter1: NSDateFormatter = NSDateFormatter()
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
                
                if self.did == "" {
                    if let selectedDID = CoreDID.getSelectedDID(self.managedObjectContext) {
                        self.did = selectedDID.did
                    }
                }
                
                self.searchBar.text = ""
                self.searchBar.resignFirstResponder()
                
            } else {
                detailSegue.contactId = self.contactForSegue
            }
        
            detailSegue.did = self.did
            detailSegue.moc = self.managedObjectContext
            detailSegue.delegate = self
        }
        
        if segue.identifier == "segueToNewMessage" {
            let newMsgVC = segue.destinationViewController as? NewMessageViewController
            newMsgVC?.did = self.did
            newMsgVC?.delegate = self
            newMsgVC?.moc = self.managedObjectContext
        }
    
    }
    
    
}
