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

class MessageDetailViewController: UIViewController, UITableViewDelegate, UIScrollViewDelegate, UITextViewDelegate, NSFetchedResultsControllerDelegate {

//    @IBOutlet weak var textMessage: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textMessage: UITextView!

    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
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

//    var coreDid = CoreDID()
//    var delegate:UpdateMessagesTableViewDelegate? = nil
    
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
            println(selectedDID.did)
            self.did = selectedDID.did
        }

        if textMessage.text == "" {
            sendButton.enabled = false
        }
        self.textMessage.delegate = self
        self.textMessage.sizeToFit()
        
        tableView.separatorStyle = .None
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
        self.tableViewHeightConstraint.constant = model.rawValue - 110
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        
        var error : NSError? = nil
        if (messageFetchedResultsController.performFetch(&error)==false) {
            println("An error has occurred: \(error?.localizedDescription)")
        }

        CoreContact.updateMessagesToRead(moc, contactId: contactId, did: did)
        startTimer()
        compressedTableViewHeight = self.tableView.frame.size.height
        
        dynamicBarButton = UIBarButtonItem(title: "Details", style: UIBarButtonItemStyle.Plain, target: self, action: "segueToContactDetails:")
        
        self.navigationItem.rightBarButtonItem = dynamicBarButton
        
        if let currentUser = CoreUser.currentUser(self.moc) {
            if currentUser.initialLoad.boolValue == true {
                currentUser.initialLoad = false
                CoreUser.updateInManagedObjectContext(self.moc, coreUser: currentUser)
            }
        }
        
        //refactor this - only call this when user navigates from new message
        let lastMessage = messageFetchedResultsController.fetchedObjects?.last! as! CoreMessage
        if lastMessage.flag == message_status.PENDING.rawValue {
            self.processMessage(lastMessage)
        }
        self.tableView.reloadData()

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

        var error : NSError? = nil
        if messageFetchedResultsController.fetchedObjects?.count > 0 {
            var lastMessage = messageFetchedResultsController.fetchedObjects?.last! as! CoreMessage
            if let lastMsg = CoreContact.getLastIncomingMessageFromContact(moc, contactId: contactId, did: did) {
                let lastMsgDate = lastMsg.date
                Message.getIncomingMessagesFromAPI(self.moc, did: did, contact: contactId, from: lastMsgDate.strippedDateFromString(), completionHandler: { (responseObject, error) -> () in
                    if responseObject.count > 0 {
                        var error: NSError? = nil
                        if (self.messageFetchedResultsController.performFetch(&error)==false) {
                            println("An error has occurred: \(error?.localizedDescription)")
                        }
                    }                    
                })
            }
        }

    }
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "dataSourceRefreshTimerDidFire:", userInfo: nil, repeats: true)
        } //else {
//            let alert = UIAlertView(title: "Network Error", message: "You need to be connected to the network to be able to send and receive messages", delegate: self, cancelButtonTitle: "Ok")
//            alert.show()
//        }
        

    }
    
    func stopTimer() {
        timer.invalidate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.tableViewScrollToBottomAnimated(false)
        self.tableViewScrollToBottomAnimated(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)

        Contact().getContactsDict({ (contacts) -> () in
            if contacts[self.contactId] != nil {
                let cText = contacts[self.contactId]?.stringByReplacingOccurrencesOfString("nil", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                self.navigationController?.navigationBar.topItem?.title = cText
                
            } else {
                self.navigationController?.navigationBar.topItem?.title = self.contactId //self.contactId.northAmericanPhoneNumberFormat()
            }
        })

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableViewScrollToBottomAnimated(false)
            self.tableViewScrollToBottomAnimated(false)
        })
//        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.timer.invalidate()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Scroll View Delegate Methods
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        
        var scrollDirection = ScrollDirection()
        if self.lastContentOffset > scrollView.contentOffset.y {
            scrollDirection = ScrollDirection.ScrollDirectionUp
            println("yes")
        }
        if self.lastContentOffset < scrollView.contentOffset.y {
            scrollDirection = ScrollDirection.ScrollDirectionDown
            println("no")

            self.textMessage.resignFirstResponder()

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
                println("insert")
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            case .Delete:
                println("del")
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
        self.tableView.endUpdates()
    }
    

    
    //MARK: -tableView delegates
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = messageFetchedResultsController.sections {
            //use the below for sections - look at sectionkeynamepath in the fetchedresultscontroller to create sections
            return sections.count
        }
        return 0
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = messageFetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let message = messageFetchedResultsController.objectAtIndexPath(indexPath) as? CoreMessage {
            var deleteViewButton = self.view.viewWithTag(indexPath.row + 100)
            if deleteMenuActivated {
                if deleteViewButton!.backgroundColor == UIColor.lightGrayColor() {
                    deleteViewButton!.backgroundColor = nil
                    messagesToDelete.removeValueForKey(indexPath.row + 100)
                } else {
                    deleteViewButton!.backgroundColor = UIColor.lightGrayColor()
                    messagesToDelete.updateValue(message, forKey: indexPath.row + 100)
                }
            }
        }
        
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath == self.selectedIndexPath {
            if self.messageFetchedResultsController.fetchedObjects?.count > 0 {
                NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("updateView"), userInfo: nil, repeats: false)
                self.messagesToDelete.updateValue(self.messageFetchedResultsController.objectAtIndexPath(indexPath) as! CoreMessage, forKey: indexPath.row + 100)
            }
        }
    }
    
    func updateView() {
        var delView = self.view.viewWithTag(selectedIndexPath.row + 100)!
        delView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = NSStringFromClass(MessageBubbleCell)
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! MessageBubbleCell!

        cell = MessageBubbleCell(style: .Default, reuseIdentifier: cellIdentifier)
        cell.userInteractionEnabled = true;
        // Add gesture recognizers #CopyMessage
        let action: Selector = "messageShowMenuAction:"
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
        tapGestureRecognizer.numberOfTapsRequired = 2
        cell.bubbleImageView.addGestureRecognizer(tapGestureRecognizer)
        cell.bubbleImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: action))
        if let message = messageFetchedResultsController.objectAtIndexPath(indexPath) as? CoreMessage {
            cell.configureWithMessage(message)
            var size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingExpandedSize)
            allCellHeight += (size.height + 10)
            self.configureAccessoryView(cell, message: message)
            
            if deleteMenuActivated {
                btnDeleteMessage = UIButton(frame: CGRectMake(cell.frame.origin.x + 15, cell.center.y / 2, 25, 25))
                btnDeleteMessage.layer.borderWidth = 2.0
                btnDeleteMessage.layer.borderColor = UIColor.blueColor().CGColor
                btnDeleteMessage.layer.cornerRadius = btnDeleteMessage.frame.size.width / 2
                btnDeleteMessage.addTarget(self, action: "deleteMenuButtonSelected:", forControlEvents: UIControlEvents.TouchUpInside)
                
                viewDeleteMessageIcon = UIView(frame: CGRectMake(cell.frame.origin.x + 15, cell.center.y / 2, 25, 25))
                viewDeleteMessageIcon.layer.borderWidth = 2.0
                viewDeleteMessageIcon.layer.borderColor = UIColor.blueColor().CGColor
                viewDeleteMessageIcon.tag = indexPath.row + 100
                viewDeleteMessageIcon.layer.cornerRadius = viewDeleteMessageIcon.frame.size.width / 2
                
                cell.accessoryView = viewDeleteMessageIcon

                
                var deleteActionView = UIView(frame: CGRectMake(self.textMessage.frame.origin.x, self.textMessage.frame.origin.y, self.view.frame.width, self.textMessage.frame.size.height))
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
        if textMessage.text == "" {
            sendButton.enabled = false
        } else {
            sendButton.enabled = true
        }
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
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
//        if self.tableViewHeightConstraint.constant < compressedTableViewHeight {
//            self.tableViewHeightConstraint.constant = compressedTableViewHeight
//        }

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
//                        tableViewHeightConstraint.constant = compressedTableViewHeight - (keyboardViewEndFrame.height - 80)
//                        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
//                        scrollView.contentInset = contentInsets;
//                        scrollView.scrollIndicatorInsets = contentInsets;
//                    } else {
                        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
                        scrollView.scrollIndicatorInsets = scrollView.contentInset
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
        var lastMessage = messageFetchedResultsController.fetchedObjects?.last as! CoreMessage
        let indexPath = messageFetchedResultsController.indexPathForObject(lastMessage)
            tableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Top,
                animated: animated)
        }
    }
    
    //MARK: - Button actions
    @IBAction func sendWasPressed(sender: AnyObject) {
        var msg : String = self.textMessage.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        var msgForCoreData = self.textMessage.text
        self.textMessage.text = ""
    
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var dateStr = formatter.stringFromDate(date)
        self.tableViewScrollToBottomAnimated(true)
        
        NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "timerDidFire:", userInfo: nil, repeats: false)
    
        CoreMessage.createInManagedObjectContext(self.moc, contact: self.contactId, id: "", type: false, date: dateStr, message: msgForCoreData, did: self.did, flag: message_status.PENDING.rawValue) { (responseObject, error) -> () in
            if error == nil {
                if let cm = responseObject {
                    self.messageFetchedResultsController.performFetch(nil)
                    self.processMessage(cm)
                }
                
            }
        }
    }
    
    func timerDidFire(sender: NSTimer) {
        self.tableViewScrollToBottomAnimated(true)
    }
    
    func processMessage(cm: CoreMessage) {
        println(cm.date)
        if let currentContact = CoreContact.currentContact(self.moc, contactId: self.contactId) {
            var formatter1: NSDateFormatter = NSDateFormatter()
            formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let parsedDate: NSDate = formatter1.dateFromString(cm.date)!
            currentContact.lastModified = parsedDate
            CoreContact.updateContactInMOC(self.moc)
        }
        
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, { () -> Void in
            Message.sendMessageAPI(self.contactId, messageText: cm.message, did: self.did, completionHandler: { (responseObject, error) -> () in
                if responseObject["status"].stringValue == "success" {
                    cm.id = responseObject["sms"].stringValue
                    cm.flag = message_status.DELIVERED.rawValue
                    CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: cm)
                } else {
                    cm.flag = message_status.UNDELIVERED.rawValue
                    CoreMessage.updateInManagedObjectContext(self.moc, coreMessage: cm)
                }
            })
        })
    }
    
    func configureAccessoryView(cell: UITableViewCell, message: CoreMessage) {
        
        cell.accessoryView?.removeFromSuperview()
        if message.id == "" {
            if ((message.flag == message_status.PENDING.rawValue) && (self.isLastMessage(message))) {
                var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
                activityIndicator.tag = 10
                activityIndicator.startAnimating()
                cell.accessoryView = activityIndicator
            }
            if message.flag == message_status.UNDELIVERED.rawValue {
                var btnFrame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 24, 24)
                var btnRetry = UIButton(frame: btnFrame)
                btnRetry.backgroundColor = UIColor.redColor()
                btnRetry.layer.cornerRadius = btnRetry.frame.size.width / 2
                btnRetry.clipsToBounds = true
                cell.accessoryView = btnRetry
            }
        }                
    }
    
    func isLastMessage(message: CoreMessage) -> Bool {
        var lastMessage = self.messageFetchedResultsController.fetchedObjects?.last! as! CoreMessage
        println(lastMessage.id)
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
            menuController.menuItems = [UIMenuItem(title: "Copy", action: "messageCopyTextAction:"), UIMenuItem(title: "More...", action: "activateDeleteAction:")]
            menuController.setMenuVisible(true, animated: true)
            self.selectedIndexPath = pressedIndexPath
        }
    }
    // 2. Copy text to pasteboard
    func messageCopyTextAction(menuController: UIMenuController) {
        let selectedIndexPath = tableView.indexPathForSelectedRow()
        println("copying")
        let selectedMessage = messageFetchedResultsController.objectAtIndexPath(selectedIndexPath!) as! CoreMessage
        UIPasteboard.generalPasteboard().string = selectedMessage.message
    }
    // 3. Deselect row
    func menuControllerWillHide(notification: NSNotification) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        (notification.object as! UIMenuController).menuItems = nil
        dynamicBarButton.title = "Details"
        dynamicBarButton.action = "segueToContactDetails:"
        println("hidden")

        
    }
    //4: Activate delete action
    func activateDeleteAction(menuController: UIMenuController) {
        deleteMenuActivated = true
        dynamicBarButton.title = "Cancel"
        dynamicBarButton.action = "cancelDeleteAction:"
        self.tableView.reloadData()
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
        }
        self.messagesToDelete.removeAll(keepCapacity: false)
        deleteMenuActivated = false
        self.messageFetchedResultsController.performFetch(nil)
        self.tableView.reloadData()
    }
    
    func cancelDeleteAction(sender: UIButton) {
        deleteMenuActivated = false
        self.tableView.reloadData()
        dynamicBarButton.title = "Details"
        dynamicBarButton.action = "segueToContactDetails:"
        var btnDeleteToRemove = self.view.viewWithTag(30)
        btnDeleteToRemove?.removeFromSuperview()
        var deleteView = self.view.viewWithTag(31)
        deleteView?.removeFromSuperview()
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if (segue.identifier == "showContactDetailSegue") {
            var actionSegue : ContactActionViewController = segue.destinationViewController as! ContactActionViewController
            actionSegue.contactId = self.contactId
            timer.invalidate()
        }
    }

}
