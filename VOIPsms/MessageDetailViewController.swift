//
//  MessageDetailViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData


enum ModelSize: CGFloat  {
    case IPHONE_4 = 480
    case IPHONE_5 = 568
    case IPHONE_6 = 667
    case IPHONE_6P = 736
    
    init() {
        self = .IPHONE_6
    }
}

enum ScrollDirection {
    case ScrollDirectionNone
    case ScrollDirectionRight
    case ScrollDirectionLeft
    case ScrollDirectionUp
    case ScrollDirectionDown
    case ScrollDirectionCrazy
    
    init() {
        self = .ScrollDirectionUp
    }
}

struct IOSModel {
    
    var screenSize : CGFloat!
    var model: ModelSize!
    var compressedHeight : CGFloat!
    
    init(screen: CGFloat) {
        self.screenSize = screen
        switch screenSize {
        case 480:
            self.model = ModelSize.IPHONE_4
        case 568:
            self.model = ModelSize.IPHONE_5
        case 667:
            self.model =  ModelSize.IPHONE_6
        case 736:
            self.model = ModelSize.IPHONE_6P
        default:
            self.model = ModelSize.IPHONE_6
        }
        
    }
    
    init(model: ModelSize) {
        self.model = model
        switch model {
        case .IPHONE_4:
            self.compressedHeight = 120
        case .IPHONE_5:
            self.compressedHeight = 208
        case .IPHONE_6:
            self.compressedHeight = 301
        case .IPHONE_6P:
            self.compressedHeight = 350
        default:
            self.compressedHeight = 301
        }
    }
    
}

class MessageDetailViewController: UIViewController, UITableViewDelegate, UIScrollViewDelegate, UITextViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate, MessageListViewDelegate {
    
    //    @IBOutlet weak var textMessage: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textMessage: UITextView!
    
    var moc : NSManagedObjectContext! //CoreDataStack().managedObjectContext!
    var messages : [CoreMessage]!
    var contactId = String()
    var cellHeights = [CGFloat]()
    var allCellHeight = CGFloat()
    var lastContentOffset = CGFloat()
    var model = ModelSize()
    var did = String()
    var titleText = String()
    var tableData : [Message] = [Message]()
    var timer : NSTimer = NSTimer()
    var compressedTableViewHeight : CGFloat = CGFloat()
    var deleteMenuActivated : Bool = false
    var dynamicBarButton : UIBarButtonItem = UIBarButtonItem()
    var btnDeleteMessage : UIButton = UIButton()
    var viewDeleteMessageIcon : UIView = UIView()
    var messagesToDelete = [Int:CoreMessage]()
    var selectedIndexPath = NSIndexPath()
    var btnDeleteSelectedMessages : UIButton = UIButton()
    var deleteActionView : UIView = UIView()
    var scrollDirection = ScrollDirection()
    var tableFullyLoaded = false
    var retrying : Bool = false
    var offsetHeight = CGFloat()
    
    var delegate:MessageListViewDelegate? = nil
    
    lazy var messageFetchedResultsController: NSFetchedResultsController = {
        let messagesFetchRequest = NSFetchRequest(entityName: "CoreMessage")
        
        let primarySortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        messagesFetchRequest.sortDescriptors = [primarySortDescriptor]
        
        let msgDIDPredicate = NSPredicate(format: "did == %@", self.did)
        let contactPredicate = NSPredicate(format: "contactId == %@", self.contactId)
        let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [msgDIDPredicate, contactPredicate])
        messagesFetchRequest.predicate = compoundPredicate
        let frc = NSFetchedResultsController(
            fetchRequest: messagesFetchRequest,
            managedObjectContext: self.moc,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.scrollView.delegate = self
        if let selectedDID = CoreDID.getSelectedDID(moc) {
            self.did = selectedDID.did
        }

        if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            sendButton.enabled = false
        }
        self.textMessage.delegate = self
        self.textMessage.sizeToFit()
        self.textMessage.scrollEnabled = false
        
        
        tableView.separatorStyle = .None
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
        self.tableViewHeightConstraint.constant = model.rawValue - 110
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        
        do {
            try messageFetchedResultsController.performFetch()
        } catch _ {
        }

        compressedTableViewHeight = self.tableView.frame.size.height
        
        if let currentUser = CoreUser.currentUser(self.moc) {
            if currentUser.initialLoad.boolValue == true || currentUser.initialLoad == 1 {
                currentUser.initialLoad = 0
                CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
            }
            
            if currentUser.notificationLoad == 1 || currentUser.notificationLoad.boolValue {
                currentUser.notificationLoad = 0
                CoreDataStack().saveContext(moc)
            }
        }
        
        if let lastMessage = messageFetchedResultsController.fetchedObjects?.last! as? CoreMessage {
            if lastMessage.flag == message_status.PENDING.rawValue {
                print("last message here")
                self.processMessage(lastMessage)
            }
            if lastMessage.flag == message_status.DELIVERED.rawValue {
                if lastMessage.type.boolValue == true || lastMessage.type == 1 {
                    lastMessage.flag = message_status.READ.rawValue
                    CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: lastMessage)
                }
            }
        }
        startTimer()
    }
    
    
    @IBAction func handleSwipe(sender: AnyObject) {
        print("handle swipe down")
        self.textMessage.resignFirstResponder()
    }
    
        
    func segueToContactDetails(sender: UIBarButtonItem) {
        Contact().getContactsDict { (contacts) -> () in
            if contacts[self.contactId] != nil {
                self.performSegueWithIdentifier("showExistingContactDetailSegue", sender: self)
            } else {
                self.performSegueWithIdentifier("showContactDetailSegue", sender: self)
            }
        }
    }
    
    func dataSourceRefreshTimerDidFire(sender: NSTimer) {
        
        self.messageFetchedResultsController.fetchRequest.predicate = nil
        Message.getIncomingMessagesFromAPI(self.moc, did: self.did, contact: self.contactId, from: nil) { (responseObject, error) -> () in
            print("messages downloaded")
        }

        let msgDIDPredicate = NSPredicate(format: "did == %@", self.did)
        let contactPredicate = NSPredicate(format: "contactId == %@", self.contactId)
        let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [msgDIDPredicate, contactPredicate])
        let primarySortDescriptor = NSSortDescriptor(key: "dateForSort", ascending: true)
        self.messageFetchedResultsController.fetchRequest.sortDescriptors = [primarySortDescriptor]
        self.messageFetchedResultsController.fetchRequest.predicate = compoundPredicate
        do {
            try self.messageFetchedResultsController.performFetch()
        } catch _ {
        }

    }
    
    func startTimer() {
        var time = NSTimeInterval()
        if Reachability.isConnectedToNetwork() {
            if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
                time = 115
            } else {
                time = 4
            }
            timer = NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: "dataSourceRefreshTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        timer.invalidate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        //        self.tableView.reloadData()
        self.tableViewScrollToBottomAnimated(false)
        self.tableViewScrollToBottomAnimated(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)

        if let currentContactFullName = CoreContact.currentContact(self.moc, contactId: self.contactId)?.fullName {
//            self.navigationController?.navigationBar.topItem?.title = currentContactFullName.truncatedString()
            self.title = currentContactFullName.truncatedString()
        } else {
            self.dynamicBarButton = UIBarButtonItem(title: "Details", style: UIBarButtonItemStyle.Plain, target: self, action: "segueToContactDetails:")
            self.navigationItem.rightBarButtonItem = self.dynamicBarButton
//            self.navigationController?.navigationBar.topItem?.title = self.contactId.northAmericanPhoneNumberFormat() //self.contactId.northAmericanPhoneNumberFormat()
            self.title = self.contactId.northAmericanPhoneNumberFormat()
        }

        self.tableViewScrollToBottomAnimated(false)
        self.tableViewScrollToBottomAnimated(false)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.timer.invalidate()
//        if let lastMessage = CoreContact.getLastIncomingMessageFromContact(self.moc, contactId: self.contactId, did: self.did) {
//            if lastMessage.type == 1 || lastMessage.type.boolValue == true {
//                lastMessage.flag = message_status.READ.rawValue
//                CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: lastMessage)
//            }
//        }
//        self.delegate?.updateMessagesTableView!()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Scroll View Delegate Methods
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        if self.lastContentOffset > scrollView.contentOffset.y {
            scrollDirection = ScrollDirection.ScrollDirectionUp
            print("yes")
        }
        if self.lastContentOffset < scrollView.contentOffset.y {
            scrollDirection = ScrollDirection.ScrollDirectionDown
            print("no")
            if scrollView == self.scrollView {
              self.textMessage.resignFirstResponder()
            }
//            self.textMessage.resignFirstResponder()
            
        }
        
        self.lastContentOffset = scrollView.contentOffset.y
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    //MARK: Core Data Delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if controller == messageFetchedResultsController {
            switch type {
            case .Insert:
                print("inserting")
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Bottom)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.None)
            case .Update:
                print("updating")
                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            default:
                self.tableView.reloadData()
            }
        }
    }
    
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        
//        if controller == messageFetchedResultsController {
//            switch type {
//            case .Insert:
//                print("inserting")
//                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Bottom)
//            case .Delete:
//                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.None)
//            case .Update:
//                print("updating")
//                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
//            default:
//                self.tableView.reloadData()
//            }
//        }
//    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()

//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            self.messageFetchedResultsController.performFetch(nil)
            self.tableViewScrollToBottomAnimated(true)
            self.tableViewScrollToBottomAnimated(true)
//        })
    }
    
    
    
    //MARK: -tableView delegates
    
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
        let indexPaths = tableView.indexPathsForVisibleRows
        
        let test = indexPaths!.last
        if test.row == indexPath.row {
            if !self.tableFullyLoaded {
                if !deleteMenuActivated {
                    print("asdfdsfasfdsdsfdsdf potential problem here")
//                    self.tableViewScrollToBottomAnimated(false)
//                    self.tableViewScrollToBottomAnimated(false)
                }
                self.tableFullyLoaded = true
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = messageFetchedResultsController.sections {
            //use the below for sections - look at sectionkeynamepath in the fetchedresultscontroller to create sections
            return sections.count
        }
        return 0
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = messageFetchedResultsController.sections {
            let currentSection = sections[section] 
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let message = messageFetchedResultsController.objectAtIndexPath(indexPath) as? CoreMessage {
            let deleteViewButton = self.view.viewWithTag(indexPath.row + 100)
            if deleteMenuActivated {
                if deleteViewButton!.backgroundColor == UIColor.lightGrayColor() {
                    deleteViewButton!.backgroundColor = nil
                    messagesToDelete.removeValueForKey(indexPath.row + 100)
                } else {
                    deleteViewButton!.backgroundColor = UIColor.lightGrayColor()
                    messagesToDelete.updateValue(message, forKey: indexPath.row + 100)
                }
            } else {
                //retry button exists
                if message.flag == message_status.UNDELIVERED.rawValue {
//                    if (self.view.viewWithTag(33000) != nil) {
                        let cell = self.tableView.cellForRowAtIndexPath(self.messageFetchedResultsController.indexPathForObject(message)!)
                        let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
                        activityIndicator.tag = 10
                        cell!.accessoryView = activityIndicator
                        activityIndicator.startAnimating()
                        self.retrying = true
                        processMessage(message)
//                    }
                }
                
            }
        }
        
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath == self.selectedIndexPath {
            if self.messageFetchedResultsController.fetchedObjects?.count > 0 {
                NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("updateView"), userInfo: nil, repeats: false)
            }
        }
        
    }
    
    func updateView() {
        if deleteMenuActivated {
            if let delView = self.view.viewWithTag(selectedIndexPath.row + 100) {
                delView.backgroundColor = UIColor.lightGrayColor()
                //            self.messagesToDelete.removeAll(keepCapacity: false)
                self.messagesToDelete.updateValue(self.messageFetchedResultsController.objectAtIndexPath(selectedIndexPath) as! CoreMessage, forKey: selectedIndexPath.row + 100)
            }
           
            
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                for v in self.view.subviews {
                    let vi = v 
                    if vi.tag == 31 || vi.tag == 30 {
                        vi.removeFromSuperview()
                    }
                }
                self.dynamicBarButton.title = "Details"
                self.dynamicBarButton.action = "segueToContactDetails:"
            })
        }
//        tableViewScrollToBottomAnimated(true)
//        tableViewScrollToBottomAnimated(true)
        
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = NSStringFromClass(MessageBubbleCell)
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! MessageBubbleCell!
        
        cell = MessageBubbleCell(style: .Default, reuseIdentifier: cellIdentifier)
//        cell.userInteractionEnabled = true;
        
        if cell != nil {
            // Add gesture recognizers #CopyMessage
            let action: Selector = "messageShowMenuAction:"
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
            tapGestureRecognizer.numberOfTapsRequired = 2
            cell.bubbleImageView.addGestureRecognizer(tapGestureRecognizer)
            cell.bubbleImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: action))
        }
        
        if let message = messageFetchedResultsController.objectAtIndexPath(indexPath) as? CoreMessage {
            cell.configureWithMessage(message)
            
            let size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingExpandedSize)
            allCellHeight += (size.height + 10)
            self.configureAccessoryView(cell, message: message)
            
            if deleteMenuActivated {
                
                viewDeleteMessageIcon = UIView(frame: CGRectMake(cell.frame.origin.x + 15, cell.center.y / 2, 25, 25))
                viewDeleteMessageIcon.layer.borderWidth = 2.0
                viewDeleteMessageIcon.layer.borderColor = UIColor.blueColor().CGColor
                viewDeleteMessageIcon.tag = indexPath.row + 100
                viewDeleteMessageIcon.layer.cornerRadius = viewDeleteMessageIcon.frame.size.width / 2
                cell.accessoryView = viewDeleteMessageIcon
                if let val = messagesToDelete[indexPath.row + 100] {
                    viewDeleteMessageIcon.backgroundColor = UIColor.lightGrayColor()
                }
                deleteActionView = UIView(frame: CGRectMake(self.textMessage.frame.origin.x, self.textMessage.frame.origin.y, self.view.frame.width, self.textMessage.frame.size.height))
                deleteActionView.backgroundColor = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1)
                deleteActionView.tag = 30
                view.addSubview(deleteActionView)
                
                let btnDeleteSelectedMessagesFrame = CGRectMake(self.sendButton.frame.origin.x + 16,self.sendButton.frame.origin.y + 7, 35, 30)
                btnDeleteSelectedMessages = UIButton(frame: btnDeleteSelectedMessagesFrame)
                btnDeleteSelectedMessages.setImage(UIImage(named: "trash"), forState: UIControlState.Normal)
                btnDeleteSelectedMessages.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                btnDeleteSelectedMessages.enabled = true
                btnDeleteSelectedMessages.tag = 31
                btnDeleteSelectedMessages.addTarget(self, action: "deleteMessages:", forControlEvents: UIControlEvents.TouchUpInside)
                view.addSubview(btnDeleteSelectedMessages)
                view.bringSubviewToFront(btnDeleteSelectedMessages)
            } else {
                
            }
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    //MARK: MessageViewDelegate methods
    
    //    func refreshRequestedData(tableData: [Trash], tableDataAssets: [TrashAssets]) {
    //        delegate?.refreshRequestedData!(tableData, tableDataAssets: tableDataAssets)
    //    }
    
    
    //MARK: - textView delegates
    
    func textViewDidChange(textView: UITextView) {
        if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            sendButton.enabled = false
        } else {
            sendButton.enabled = true
        }

        let offsetHeightTV = textView.frame.size.height
        
        self.tableView.frame.size.height = compressedTableViewHeight - offsetHeight
        self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight - offsetHeightTV + 30
        //                                    self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;

    }
    

    
    //MARK: - textField delegates
    func textFieldChange(sender: UITextField) {
        if textMessage.text == "" {
            sendButton.enabled = false
        } else {
            sendButton.enabled = true
        }
    }
    //MARK: - Keyboard delegates
    
    
    func keyboardWillHide(sender: NSNotification) {
//        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
//        scrollView.contentInset = contentInsets;
//        scrollView.scrollIndicatorInsets = contentInsets;
        
       
        switch model.rawValue {
            case 480:
                self.tableView.frame.size.height = compressedTableViewHeight - 115
                self.tableViewHeightConstraint.constant = compressedTableViewHeight - 115
            case 568:
                self.tableView.frame.size.height = compressedTableViewHeight - 30
                self.tableViewHeightConstraint.constant = compressedTableViewHeight - 30
            case 667:
                self.tableView.frame.size.height = compressedTableViewHeight + 70
                self.tableViewHeightConstraint.constant = compressedTableViewHeight + 70
            case 736:
                self.tableView.frame.size.height = compressedTableViewHeight + 120
                self.tableViewHeightConstraint.constant = compressedTableViewHeight + 120
            default:
                self.tableView.frame.size.height = compressedTableViewHeight + 60
                self.tableViewHeightConstraint.constant = compressedTableViewHeight + 60
        }
        
        
        
    }
    
    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        
        if notification.name == UIKeyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsetsZero
        } else {
            
            if notification.name == UIKeyboardWillChangeFrameNotification {
                if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                    if allCellHeight < keyboardScreenEndFrame.height  {

                    
                    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                        //                println(model.rawValue)
                        //                case IPHONE_4 = 480
                        //                case IPHONE_5 = 568
                        //                case IPHONE_6 = 667
                        //                case IPHONE_6P = 736

                        switch model.rawValue {
                        case 480:
                            offsetHeight = keyboardScreenEndFrame.height + 115
                        case 568:
                            offsetHeight = keyboardScreenEndFrame.height + 30
                        case 667:
                            offsetHeight = keyboardScreenEndFrame.height - 70
                        case 736:
                            offsetHeight = keyboardScreenEndFrame.height - 120
                        default:
                            offsetHeight = keyboardScreenEndFrame.height - 60
                        }
                        
                        if notification.name == UIKeyboardWillChangeFrameNotification {
                            self.tableView.frame.size.height = compressedTableViewHeight - offsetHeight
                                self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight
                            let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
                            scrollView.contentInset = contentInsets;
//                            self.tableViewScrollToBottomAnimated(true)
                        }
                    }
//                    } else {
//                        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height + 10, right: 0)
//                        scrollView.scrollIndicatorInsets = scrollView.contentInset
//                    }
                }
            }
            
        }
        
        tableViewScrollToBottomAnimated(true)
        
    }
    
    func tableViewScrollToBottomAnimated(animated: Bool) {
        let numberOfRows = tableView.numberOfRowsInSection(0)
        if numberOfRows > 0 {
            //        let indexPath = NSIndexPath(forRow: self.tableData.endIndex - 1, inSection: 0)
            if let lastMessage = messageFetchedResultsController.fetchedObjects?.last as? CoreMessage {
                let indexPath = messageFetchedResultsController.indexPathForObject(lastMessage)
                tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Top,
                    animated: animated)
            }
        }
    }
    
    //MARK: - Button actions
    
    
    
    @IBAction func sendWasPressed(sender: AnyObject) {

        let msgForCoreData = self.textMessage.text
        self.textMessage.text = ""
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let dateStr = formatter.stringFromDate(date)
        
        CoreMessage.createInManagedObjectContext(self.moc, contact: self.contactId, id: "", type: false, date: dateStr, message: msgForCoreData, did: self.did, flag: message_status.PENDING.rawValue) { (responseObject, error) -> () in
            if error == nil {
                if let cm = responseObject {
                    self.processMessage(cm)
                }
            }
        }
        
//        var offsetHeightTV = self.textMessage.frame.size.height
        
        self.tableView.frame.size.height = compressedTableViewHeight - offsetHeight
        self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight //- offsetHeightTV + 30
        //                                    self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
    }

    
    func processMessage(cm: CoreMessage) {

        let msg : String = cm.message.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!        
        if Reachability.isConnectedToNetwork() {
            self.moc.performBlock({ () -> Void in
                Message.sendMessageAPI(self.contactId, messageText: msg, did: self.did, completionHandler: { (responseObject, error) -> () in
                    if responseObject["status"].stringValue == "success" {
                        cm.id = responseObject["sms"].stringValue
                        cm.flag = message_status.DELIVERED.rawValue
                        let formatter1: NSDateFormatter = NSDateFormatter()
                        formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                        let parsedDate: String = formatter1.stringFromDate(NSDate())
                        cm.date = parsedDate
                        print("looks ok")
                    } else {
                        cm.flag = message_status.UNDELIVERED.rawValue
                        print("looks bad")
                    }
                })
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: cm)
                })
            })
        } else {
            if !retrying {
                cm.flag = message_status.UNDELIVERED.rawValue
                CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: cm)
            } else {
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, { () -> Void in
                    sleep(1)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let cell = self.tableView.cellForRowAtIndexPath(self.messageFetchedResultsController.indexPathForObject(cm)!)
                        self.configureAccessoryView(cell!, message: cm)
                    })
                })
            }
        }
        
    }
    
    func configureAccessoryView(cell: UITableViewCell, message: CoreMessage) {
        
        cell.accessoryView?.removeFromSuperview()
        if message.id == "" {
            if ((message.flag == message_status.PENDING.rawValue) && (self.isLastMessage(message))) {
                let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
                activityIndicator.tag = 10
                activityIndicator.startAnimating()
                cell.accessoryView = activityIndicator
            }
            if message.flag == message_status.UNDELIVERED.rawValue {
                let btnFrame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 24, 24)
                let btnRetry = UIView(frame: btnFrame)
                btnRetry.backgroundColor = UIColor.redColor()
                btnRetry.tag = 33000
                btnRetry.layer.cornerRadius = btnRetry.frame.size.width / 2
                btnRetry.clipsToBounds = true
                cell.accessoryView = btnRetry
            }
        }
        
    }
    
    func retryWasPressed(sender: UIButton) {
        print("hi")
        //        let cm : CoreMessage = self.messageFetchedResultsController.objectAtIndexPath(self.selectedIndexPath) as! CoreMessage
        //        processMessage(cm)
    }
    
    func isLastMessage(message: CoreMessage) -> Bool {
        let lastMessage = self.messageFetchedResultsController.fetchedObjects?.last! as! CoreMessage
        if message.id == lastMessage.id {
            return true
        }
        return false
    }
    
    // Handle actions #CopyMessage
    // 1. Select row and show "Copy" menu
    
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    func messageShowMenuAction(gestureRecognizer: UITapGestureRecognizer) {
        
        if let lm = CoreContact.getLastMessageFromContact(self.moc, contactId: self.contactId, did: self.did) {
           
            let bubbleImageView = gestureRecognizer.view!
            bubbleImageView.becomeFirstResponder()
            let twoTaps = (gestureRecognizer.numberOfTapsRequired == 2)
            let doubleTap = (twoTaps && gestureRecognizer.state == .Ended)
            let longPress = (!twoTaps && gestureRecognizer.state == .Began)
            if doubleTap || longPress {
                let pressedIndexPath = tableView.indexPathForRowAtPoint(gestureRecognizer.locationInView(tableView))!
                tableView.selectRowAtIndexPath(pressedIndexPath, animated: false, scrollPosition: .None)
                let menuController = UIMenuController.sharedMenuController()
                menuController.setTargetRect(bubbleImageView.frame, inView: bubbleImageView.superview!)
                menuController.menuItems = nil
                let copyMenuItem = UIMenuItem(title: "Copy", action: "messageCopyTextAction:")
                if lm.flag != message_status.PENDING.rawValue {
                    menuController.menuItems = [copyMenuItem, UIMenuItem(title: "More...", action: "activateDeleteAction:")]
                } else {
                    menuController.menuItems = [copyMenuItem]
                }
                
                
                if lm.flag != message_status.PENDING.rawValue {
                }
                
                menuController.setMenuVisible(true, animated: true)
                self.selectedIndexPath = pressedIndexPath
            }
        }
    }
    // 2. Copy text to pasteboard
    func messageCopyTextAction(menuController: UIMenuController) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            let selectedMessage = messageFetchedResultsController.objectAtIndexPath(selectedIndexPath) as! CoreMessage
            UIPasteboard.generalPasteboard().string = selectedMessage.message
        }
    }
    // 3. Deselect row
    func menuControllerWillHide(notification: NSNotification) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        (notification.object as! UIMenuController).menuItems = nil
        dynamicBarButton.title = "Details"
        dynamicBarButton.action = "segueToContactDetails:"
    }
    //4: Activate delete action
    func activateDeleteAction(menuController: UIMenuController) {
        self.textMessage.resignFirstResponder()
        deleteMenuActivated = true
        dynamicBarButton.title = "Cancel"
        dynamicBarButton.action = "cancelDeleteAction:"
        self.tableView.reloadData()
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
    }
    
    func deleteMenuButtonSelected(sender: UIButton) {
        let btn = sender
        if btn.backgroundColor == UIColor.lightGrayColor() {
            btn.backgroundColor = nil
        } else {
            btn.backgroundColor = UIColor.lightGrayColor()
        }
    }
    
    func deleteMessages(sender: UIButton) {
        for (key, value) in self.messagesToDelete {
            CoreMessage.deleteMessage(self.moc, coreMessage: value)
            
            let deleteViewButton = self.view.viewWithTag(key)
            deleteViewButton!.backgroundColor = nil
        }
        self.messagesToDelete.removeAll(keepCapacity: false)
        deleteMenuActivated = false
        
        do {
            try messageFetchedResultsController.performFetch()
        } catch _ {
        }
        self.tableView.reloadData()
        deleteMenuActivated = false
        self.delegate?.updateMessagesTableView!()
    }
    
    func cancelDeleteAction(sender: UIButton) {
        deleteMenuActivated = false
        self.tableView.reloadData()
        dynamicBarButton.title = "Details"
        dynamicBarButton.action = "segueToContactDetails:"
        for v in self.view.subviews {
            let vi = v 
            if vi.tag == 31 || vi.tag == 30 {
                vi.removeFromSuperview()
            }
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if (segue.identifier == "showContactDetailSegue") {
            let actionSegue : ContactActionViewController = segue.destinationViewController as! ContactActionViewController
            actionSegue.contactId = self.contactId
            actionSegue.moc = self.moc
        }
        timer.invalidate()
    }
    
}
