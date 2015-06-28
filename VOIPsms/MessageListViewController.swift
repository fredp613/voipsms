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
    optional func triggerSegue(contact: String)
}

class MessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MessageListViewDelegate {
    
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
        
        let moc = CoreDataStack().managedObjectContext!
        if let did = CoreDID.getSelectedDID(moc) {
            println("selected did is \(did.did)")
            var contactIDs = CoreMessage.getMessagesByDID(moc, did: did.did).map({$0.contactId})
            let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
            contactsFetchRequest.predicate = contactPredicate
            self.did = did.did
        }
        
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: "lastModified",
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    lazy var messageFetchedResultsController: NSFetchedResultsController = {
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreMessage")
        let primarySortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
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
        
        if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
            currentUser.initialLoad = true
            CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
        }
        
        let addMessageButton = UIBarButtonItem(title: "New", style: UIBarButtonItemStyle.Plain, target: self, action: "segueToNewMessage:")
        self.navigationItem.rightBarButtonItem = addMessageButton
        
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
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
            
            CoreUser.authenticate(managedObjectContext, email: currentUser!.email, password: pwd!, completionHandler: { (success) -> Void in
                if success == false || currentUser?.remember == false {
                    self.performSegueWithIdentifier("showLoginSegue", sender: self)
                } else {
                    if currentUser!.messagesLoaded.boolValue == false || currentUser!.messagesLoaded == 0 {
                        self.performSegueWithIdentifier("showDownloadMessagesSegue", sender: self)
                    }
                }
            })
            
        } else {
            performSegueWithIdentifier("showLoginSegue", sender: self)
        }
        startTimer()
    }
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func timerDidFire(sender: NSTimer) {
        if let str = CoreDID.getSelectedDID(managedObjectContext) {
            messageFetchedResultsController.performFetch(nil)
            if let cm = messageFetchedResultsController.fetchedObjects {
                if let currentUser = CoreUser.currentUser(self.managedObjectContext) {
                    var ogCount = cm.count
                    if currentUser.initialLogon.boolValue == false {
                        var from = ""
//                        if currentUser.initialLoad.boolValue == true {
                            if let lastMessage = cm.first as? CoreMessage {
                                from = lastMessage.date
                                Message.getMessagesFromAPI(false, moc: managedObjectContext, from: from.strippedDateFromString(), completionHandler: { (responseObject, error) -> () in
                                })
                            }
//                        }
                        
//                    } else {
//                        Message.getMessagesFromAPI(false, moc: managedObjectContext, from: str.registeredOn.strippedDateFromString(), completionHandler: { (responseObject,
//                            error) -> () in
//                        })
                    }
//                    CoreUser.updateInManagedObjectContext(self.managedObjectContext, coreUser: currentUser)
                }
                
            }
            
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Core Data Delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if controller == fetchedResultsController {
            switch type {
            case .Insert:
                println("insert")
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            case .Update:
                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            default:
                println("default change object")
                self.tableView.reloadData()
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.reloadData()
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
       //
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let contact = fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
        
        let didPredicate = NSPredicate(format: "did == %@", self.did)
        var filteredMessages = contact.messages.filteredSetUsingPredicate(didPredicate)
        
        
        let primarySortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        var sortedMessages = contact.messages.sortedArrayUsingDescriptors([primarySortDescriptor])
        var message : CoreMessage!
        if self.did != "" {
            if (sortedMessages.first != nil) {
                message = sortedMessages.filter({$0.did == self.did}).first! as! CoreMessage
                cell.detailTextLabel?.text = message.message
            }
        } else {
            if (sortedMessages.first != nil) {
                message = sortedMessages.first! as! CoreMessage
                cell.detailTextLabel?.text = message.message
            }
            if message.type.boolValue == true || message.type == 1 {
                if message.flag == message_status.PENDING.rawValue {
                    cell.textLabel?.textColor = UIColor(red: 220/255, green: 170/255, blue: 11/255, alpha: 1)
                    cell.detailTextLabel?.textColor = UIColor(red: 220/255, green: 170/255, blue: 77/255, alpha: 1)
                } else {
                    cell.textLabel?.textColor = UIColor.blackColor()
                    cell.detailTextLabel?.textColor = UIColor.blackColor()
                }
            } else {
                cell.textLabel?.textColor = UIColor.blackColor()
                cell.detailTextLabel?.textColor = UIColor.blackColor()
            }
            
        }
        
        if contact.fullName != nil {
            cell.textLabel?.text = contact.fullName
        } else {
            cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
        }
        
//        if message != nil {
        
            
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
            cell.contentView.addSubview(dateLbl)
//        }
        
        
        
        return cell
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
        
        if let dids = CoreDID.getDIDs(self.managedObjectContext) {
            self.did = dids[row].did
            CoreDID.toggleSelected(self.managedObjectContext, did: self.did)
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            if let newDID = CoreDID.getSelectedDID(self.managedObjectContext) {
                self.did = newDID.did
                let predicate = NSPredicate(format: "did == %@", self.did)
                println(self.did)
                messageFetchedResultsController.fetchRequest.predicate = predicate
                messageFetchedResultsController.performFetch(nil)
                var contactIDs = [String]()
                if let contactMessages = messageFetchedResultsController.fetchedObjects {
                    contactIDs += contactMessages.map({$0.contactId})
                    let contactPredicate = NSPredicate(format: "contactId IN %@", contactIDs)
                    fetchedResultsController.fetchRequest.predicate = contactPredicate
                    fetchedResultsController.performFetch(nil)
                }
                self.tableView.reloadData()
            }
            
        }
        maskView.removeFromSuperview()
        didView.removeFromSuperview()
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
        } else {
            clearSearch()
        }
    }
    
    func clearSearch() {
        fetchedResultsController.fetchRequest.predicate = nil
        self.fetchedResultsController.performFetch(nil)
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
    
    //MARK: Class Delegate Methods
    
    func triggerSegue(contact: String) {
        self.contactForSegue = contact
        self.performSegueWithIdentifier("showMessageDetailSegue", sender: self)
    }
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        timer.invalidate()
        if (segue.identifier == "showMessageDetailSegue") {
            self.searchBar.resignFirstResponder()
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            if self.contactForSegue != "" {
                detailSegue.contactId = self.contactForSegue
            } else {
                if let indexPath = self.tableView.indexPathForSelectedRow() {
                    detailSegue.contactId = self.fetchedResultsController.objectAtIndexPath(indexPath).contactId as String //
                }
            }
            self.contactForSegue = ""
            detailSegue.did = self.did
        }
        
        if segue.identifier == "segueToNewMessage" {
            var newMsgVC = segue.destinationViewController as? NewMessageViewController
            newMsgVC?.delegate = self
        }
    }
}
