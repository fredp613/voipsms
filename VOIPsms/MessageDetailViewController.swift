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


class MessageDetailViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, UIScrollViewDelegate {

    @IBOutlet weak var textMessage: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var messages : [CoreMessage]!
    var contactId = String()
    var cellHeights = [CGFloat]()
    var allCellHeight = CGFloat()
    var lastContentOffset = CGFloat()
    var model = ModelSize()
    var titleText = String()
//    var coreDid = CoreDID()
//    var delegate:UpdateMessagesTableViewDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.scrollView.delegate = self
        
        // Do any additional setup after loading the view.
        if textMessage.text == "" {
            sendButton.enabled = false
        }
        self.textMessage.delegate = self
        self.textMessage.addTarget(self, action: "textFieldChange:", forControlEvents: UIControlEvents.EditingChanged)
        tableView.separatorStyle = .None
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
//        tableView.keyboardDismissMode = .Interactive
//        let modelName = UIDevice.currentDevice().modelName
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
        self.tableViewHeightConstraint.constant = model.rawValue - 110
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        
        CoreContact.updateMessagesToRead(moc, contactId: contactId)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.tableViewScrollToBottomAnimated(false)
       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
         self.navigationController?.navigationBar.topItem?.title = titleText
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableViewScrollToBottomAnimated(false)
            self.tableViewScrollToBottomAnimated(false)
        })
        self.tableView.reloadData()
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
    

    

    
    //MARK: -tableView delegates
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        
            let cellIdentifier = NSStringFromClass(MessageBubbleCell)
            var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! MessageBubbleCell!
            if cell == nil {
                cell = MessageBubbleCell(style: .Default, reuseIdentifier: cellIdentifier)
                
                // Add gesture recognizers #CopyMessage
//                let action: Selector = "messageShowMenuAction:"
//                let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
//                doubleTapGestureRecognizer.numberOfTapsRequired = 2
//                cell.bubbleImageView.addGestureRecognizer(doubleTapGestureRecognizer)
//                cell.bubbleImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: action))
            }
            let message = self.messages[indexPath.row]
            cell.configureWithMessage(message)
            var size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingExpandedSize)
//            cellHeights.append(size.height + 10)
            allCellHeight += (size.height + 10)

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
    
   

    //MARK: - textField delegates
    func textFieldChange(sender: UITextField) {
        if textMessage.text == "" {
            sendButton.enabled = false
        } else {
            sendButton.enabled = true
        }
    }
    //MARK: - Keyboard delegates
//    func keyboardWillShow(sender: NSNotification) {
//        
//            if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height + 20, right: 0)
//                scrollView.contentInset = contentInsets
//                scrollView.scrollIndicatorInsets = contentInsets
//        
//                if allCellHeight < keyboardSize.height  {
//                    tableViewHeightConstraint.constant = keyboardSize.height - (keyboardSize.height * 0.17)
//                    tableViewScrollToBottomAnimated(true)
//                    let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
//                    scrollView.contentInset = contentInsets;
//                    scrollView.scrollIndicatorInsets = contentInsets;
//                } else {
//                    tableViewScrollToBottomAnimated(true)
//                }
//            }
//
//        
//        
//        
//    }
    func keyboardWillHide(sender: NSNotification) {
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }

    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        
        if notification.name == UIKeyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsetsZero
        } else {
            if notification.name == UIKeyboardWillChangeFrameNotification {
                scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - 30, right: 0)
            }

            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                if allCellHeight < keyboardSize.height  {
                    tableViewHeightConstraint.constant = IOSModel(model: self.model).compressedHeight // keyboardSize.height + (keyboardSize.height * 0.17)
                    let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
                    scrollView.contentInset = contentInsets;
                    scrollView.scrollIndicatorInsets = contentInsets;
                } else {
                    scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
                }
            }
           
        }
        
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        tableViewScrollToBottomAnimated(true)
     
    }
    
    func tableViewScrollToBottomAnimated(animated: Bool) {
        let numberOfRows = tableView.numberOfRowsInSection(0)
        if numberOfRows > 0 {
            let indexPath = NSIndexPath(forRow: self.messages.endIndex - 1, inSection: 0)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top,
                animated: animated)
        }
    }
    
    
    //MARK: - Button actions
    @IBAction func sendWasPressed(sender: AnyObject) {
        var msg : String = self.textMessage.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        if let cm =  CoreMessage.sendMessage(self.moc, contact: self.contactId, messageText: msg, did: "6135021177")  {
            self.textMessage.text = ""
            self.messages = CoreContact.getMsgsByContact(moc, contactId: self.contactId)
            self.tableView.beginUpdates()
            var indexPath = NSIndexPath(forRow: self.messages.count - 1, inSection: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
            self.tableView.endUpdates()
            self.tableViewScrollToBottomAnimated(false)
            
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) { // 1
                Message.sendMessageAPI(self.contactId, messageText: msg, did: "6135021177", completionHandler: { (responseObject, error) -> () in
                     println(responseObject)
                    if responseObject["status"].stringValue == "success" {
                        let smsId = responseObject["sms"].stringValue

                        if let cmi = CoreMessage.updateSentMessageFromAPI(self.moc, coreId: cm.coreId, id: smsId) {
                            println("success")
                        }
                        
//                        if let cm = CoreMessage.updateSentMessageFromAPI(self.moc, coreId: cm.coreId, id: smsId) {
//                            //update api date or delivered flag
//                        }
                    }
              
                })
            }

        } else {
            println("soemthing went wrong!")
        }
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
