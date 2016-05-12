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
    var offsetHeight = CGFloat()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.textMessage.delegate = self
        self.scrollView.delegate = self
        self.searchBar.delegate = self
        compressedTableViewHeight = self.tableView.frame.size.height


        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
//
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.adjustForKeyboard(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        

        self.textMessage.sizeToFit()
        currentTextViewSize = self.textMessage.contentSize.height
        self.searchBar.becomeFirstResponder()
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        scrollView.bringSubviewToFront(textMessage)
        scrollView.bringSubviewToFront(sendButton)

        if self.textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            self.sendButton.enabled = false
        }
        
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
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
            
            var cleanedSearchBarText = NSString(string: self.searchBar.text!)
            if cleanedSearchBarText.length > 10 {
                cleanedSearchBarText = cleanedSearchBarText.substringWithRange(NSMakeRange(1, 10))
                
            }
            contact = cleanedSearchBarText as String
        }

        let msgForCoreData = self.textMessage.text
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let dateStr = formatter.stringFromDate(date)
        self.textMessage.text = ""
        CoreMessage.createInManagedObjectContext(self.moc, contact: contact, id: "", type: false, date: dateStr, message: msgForCoreData, did: self.did, flag: message_status.PENDING.rawValue, completionHandler: { (responseObject, error) -> () in
            
            if let cc = CoreContact.currentContact(self.moc, contactId: contact) {
                if Contact().checkAccess() {
                    Contact().syncNewMessageContact(cc, moc: self.moc)
                }
            }
           
            
            self.delegate?.triggerSegue!(contact, moc: self.moc)
            self.dismissViewControllerAnimated(false, completion: { () -> Void in
            })

        })
    }
    
    //MARK: UITextView Delegate Methods
    
    func textViewDidBeginEditing(textView: UITextView) {
        if validateContactText(searchBar.text!) {
            if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
                sendButton.enabled = false
            } else {
                sendButton.enabled = true
            }
        } else {
            self.sendButton.enabled = false
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if validateContactText(searchBar.text!) {
            if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
                sendButton.enabled = false
            } else {
                sendButton.enabled = true
            }
        } else {
            self.sendButton.enabled = false
        }
        textView.layoutIfNeeded()
        let offsetHeightTV = textView.frame.size.height
        
        self.tableView.frame.size.height = compressedTableViewHeight - offsetHeight
        self.tableViewHeighConstraint.constant = compressedTableViewHeight - offsetHeight - offsetHeightTV + 30
        //                                    self.tableViewHeightConstraint.constant = compressedTableViewHeight - offsetHeight
        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;

    }
    
    func validateContactText(input: String) -> Bool {
        if self.selectedContact == "" {
            let strToFormat = input as NSString
            let regex = try? NSRegularExpression(pattern: "[0-9]", options: [])
            if (regex?.matchesInString(input, options: [], range: NSMakeRange(0, strToFormat.length)) != nil) {
                if strToFormat.length >= 10 && strToFormat.length <= 11 {
                   return true
                }
            }
        } else {
            return true
        }
        return false
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
            
            let privateMOC = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            privateMOC.parentContext = self.moc
            
            
            Contact().getContactsBySearchString(searchText, moc: self.moc, completionHandler: { (data) in
//                self.contacts = data
                var cstruct = [ContactStruct]()
                if let unwrappedData = data {
                    for u in unwrappedData {
                        var cStr = ContactStruct()
                        cStr.contactName = u.contactFullName
                        cStr.contactId = u.recordId
                        cStr.phoneLabel = u.phoneLabel
                        cstruct.append(cStr)
                    }
                    self.contacts = cstruct
                    self.tableView.reloadData()
                }
                
            })
            
            
//            CoreContact.getContacts(moc, did: did, dst: searchText, name: nil, message: nil, completionHandler: { (responseObject, error) -> () in
//                let coreContacts = responseObject as! [CoreContact]
//                CoreContact.findAllContactsByName(self.moc, searchTerm: searchText, existingContacts: coreContacts, completionHandler: { (contacts) -> () in
//                    self.contacts = contacts!
//                    self.tableView.reloadData()
//                })
//            })
            
        } else {
            self.contacts = [ContactStruct]()
            self.tableView.reloadData()
        }
        
        if validateContactText(searchBar.text!) {
            if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
                sendButton.enabled = false
            } else {
                sendButton.enabled = true
            }
        } else {
            self.sendButton.enabled = false
        }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        let contact = self.contacts[indexPath.row]
        
        if Contact().checkAccess() {
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
                        cell.detailTextLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
                    }
                
            }
        } else {
            
            if contact.contactName != "" {
                cell.textLabel?.text = contact.contactName
            } else {
                cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
            }
            
            if contact.phoneLabel != "" {
                cell.detailTextLabel?.text = contact.phoneLabel + ": " +  contact.contactId.northAmericanPhoneNumberFormat()
            } else {
                cell.detailTextLabel?.text = ""
            }
            
            
            cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
            cell.detailTextLabel?.text = ""

        }
    
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //update text field to show contact
        self.selectedContact = self.contacts[indexPath.row].contactId
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        
        self.searchBar.text = "\(cell!.textLabel!.text!) (\(self.contacts[indexPath.row].phoneLabel): \(self.contacts[indexPath.row].contactId))"
        
        self.contacts = [ContactStruct]()
        self.tableView.reloadData()
        
        if validateContactText(searchBar.text!) {
            if textMessage.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
                sendButton.enabled = false
            } else {
                sendButton.enabled = true
            }
        } else {
            self.sendButton.enabled = false
        }

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
            print("keyboardhiding")
            
        } else {
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
