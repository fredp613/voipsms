//
//  NewMessageViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-03.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class NewMessageViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, UISearchBarDelegate, MessageListViewDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
//    @IBOutlet weak var textContacts: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessage: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeighConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    
//    @IBOutlet weak var cancelButton: UIBarButtonItem!
    let addressBook = APAddressBook()
    var model = ModelSize()
    var contacts : [ContactStruct] = [ContactStruct]()
    var moc : NSManagedObjectContext! //= CoreDataStack().managedObjectContext!
    var did : String = String()
    var selectedContact = String()
    var delegate: MessageListViewDelegate?
    var compressedTableViewHeight : CGFloat = CGFloat()
    var currentKeyboardSize : CGFloat = CGFloat()
    var currentTextViewSize : CGFloat = CGFloat()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.textMessage.delegate = self
//        self.textContacts.delegate = self
        self.scrollView.delegate = self
        self.searchBar.delegate = self
        compressedTableViewHeight = self.tableView.frame.size.height


        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
//
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        

        self.textMessage.sizeToFit()
//        self.textMessage.layoutIfNeeded()
//        self.scrollView.bringSubviewToFront(self.textMessage)
        currentTextViewSize = self.textMessage.contentSize.height
//        self.textMessage.becomeFirstResponder()
        self.searchBar.becomeFirstResponder()
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        scrollView.bringSubviewToFront(textMessage)
        scrollView.bringSubviewToFront(sendButton)

        if self.textMessage.text == "" {
            self.sendButton.enabled = false
        }
        
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
//        self.tableViewHeighConstraint.constant = 600
        self.searchBar.resignFirstResponder()
        self.textMessage.resignFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addContactWasPressed(sender: AnyObject) {
    }

    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendMessageWasPressed(sender: AnyObject) {
        
        var contact = ""
        if selectedContact != "" {
            contact = selectedContact
        } else {
            contact = self.searchBar.text
        }
        var msg : String = self.textMessage.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var dateStr = formatter.stringFromDate(date)
        self.textMessage.text = ""
        CoreMessage.createInManagedObjectContext(self.moc, contact: contact, id: "", type: false, date: dateStr, message: msg, did: self.did, flag: message_status.PENDING.rawValue, completionHandler: { (responseObject, error) -> () in
            if let currentContact = CoreContact.currentContact(self.moc, contactId: contact) {
                var formatter1: NSDateFormatter = NSDateFormatter()
                formatter1.dateFormat = "YYYY-MM-dd HH:mm:ss"
                let parsedDate: NSDate = formatter1.dateFromString(dateStr)!
                currentContact.lastModified = parsedDate
                currentContact.deletedContact = 0
                CoreContact.updateContactInMOC(self.moc)
//                CoreContact.updateInManagedObjectContext(self.moc, contactId: contact, lastModified: dateStr,fullName: nil, phoneLabel: nil, addressBookLastModified: nil)
            } else {
                println("creating contact")
                CoreContact.createInManagedObjectContext(self.moc, contactId: contact, lastModified: dateStr)
            }
            self.delegate?.triggerSegue!(contact, moc: self.moc)
            self.dismissViewControllerAnimated(false, completion: { () -> Void in
            })

        })
    }
    
    //MARK: UITextView Delegate Methods
    func textViewDidChange(textView: UITextView) {
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
    }
    
    func keyboardWillShow() {
        if self.view.frame.origin.y >= 0 {
            self.setViewMovedUp(true)
        }
        else if self.view.frame.origin.y < 0 {
            self.setViewMovedUp(false)
        }
    }
    
    func keyboardWillHide() {
        if self.view.frame.origin.y >= 0 {
            self.setViewMovedUp(true)
        }
        else if self.view.frame.origin.y < 0 {
            self.setViewMovedUp(false)
        }
    }
    
    func setViewMovedUp(movedUp: Bool) {
        var rect = self.view.frame
        if movedUp {
            rect.origin.y -= 80
            rect.size.height += 80
        } else {
            rect.origin.y += 80
            rect.size.height -= 80
        }
        self.view.frame = rect
    }
    
    
    
    //MARK: SearchBar Delegate Methods
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText != "" {
            self.sendButton.enabled = true
            CoreContact.getContacts(moc, did: did, dst: searchText, name: nil, message: nil, completionHandler: { (responseObject, error) -> () in
                var coreContacts = responseObject as! [CoreContact]
                CoreContact.findAllContactsByName(self.moc, searchTerm: searchText, existingContacts: coreContacts, completionHandler: { (contacts) -> () in
                    self.contacts = contacts!
                    self.tableView.reloadData()
                })
            })
            
        } else {
            self.sendButton.enabled = false
            self.contacts = [ContactStruct]()
            self.tableView.reloadData()
        }
//        println(self.contacts.map({$0.phoneLabel}))
    }
 
    
    //MARK: - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        var contact = self.contacts[indexPath.row]

        Contact().getContactsDict { (contacts) -> () in
            
            let contStr = contact.contactId as String
            if contacts[contact.contactId] != nil {
                let cText = contacts[contact.contactId]?.stringByReplacingOccurrencesOfString("nil", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                cell.textLabel?.text = cText!
            } else {
                if contact.contactName != "" {
                    cell.textLabel?.text = contact.contactName
                } else {
                    cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
                }
            }
            if contact.phoneLabel != "" {
                cell.detailTextLabel?.text = contact.phoneLabel + ": " +  contact.contactId.northAmericanPhoneNumberFormat()
            } else {
                cell.detailTextLabel?.text = ""
            }
            
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //update text field to show contact
        self.selectedContact = self.contacts[indexPath.row].contactId
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        self.searchBar.text = "\(cell!.textLabel!.text!) \(self.contacts[indexPath.row].phoneLabel)"
        
        self.contacts = [ContactStruct]()
        self.tableView.reloadData()

    }
    
    //MARK: - Keyboard delegates
    
    func keyboardWillHide(sender: NSNotification) {
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
//        self.textContacts.becomeFirstResponder()
    }
    
    func adjustForKeyboard(notification: NSNotification) {
        
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        
        if notification.name == UIKeyboardWillHideNotification {
//            scrollView.contentInset = UIEdgeInsetsZero
            println("keyboardhiding")
            
        } else {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                println(model.rawValue)
//                case IPHONE_4 = 480
//                case IPHONE_5 = 568
//                case IPHONE_6 = 667
//                case IPHONE_6P = 736
                var offsetHeight = CGFloat()
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
                    self.tableViewHeighConstraint.constant = compressedTableViewHeight - offsetHeight
                    let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
                    scrollView.contentInset = contentInsets;
                }
            }
        }
    }
    
    //MARK: Custom Methods
    
    
//    func adjustForKeyboard(notification: NSNotification) {
//        let userInfo = notification.userInfo!
//        
//        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
//        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
//        
//        if notification.name == UIKeyboardWillHideNotification {
//            scrollView.contentInset = UIEdgeInsetsZero
//        } else {
//            if notification.name == UIKeyboardWillChangeFrameNotification || notification.name == UIKeyboardWillShowNotification {
//                println("hi")
//                if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                    
////                    scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
////                    scrollView.scrollIndicatorInsets = scrollView.contentInset
//                    self.tableViewHeighConstraint.constant = keyboardSize.height 
//                }
//            }
//        }
//    }
   
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showDetailSegue" {
//            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
//            detailSegue.contactId = selectedContact
//            detailSegue.did = did
//        }
    }


}
