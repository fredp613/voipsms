//
//  NewMessageViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-03.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class NewMessageViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate, MessageViewDelegate {
    @IBOutlet weak var textContacts: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessage: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeighConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    let addressBook = APAddressBook()
    var model = ModelSize()
    var contacts : [ContactStruct] = [ContactStruct]()
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var did : String = String()
    var selectedContact = String()
    var delegate: MessageViewDelegate?
    var compressedTableViewHeight : CGFloat = CGFloat()
    var currentKeyboardSize : CGFloat = CGFloat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.textMessage.delegate = self
        self.textContacts.delegate = self
        self.scrollView.delegate = self

        compressedTableViewHeight = self.tableView.frame.size.height


//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
        

        

//        self.textContacts.becomeFirstResponder()
        self.textMessage.becomeFirstResponder()
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        scrollView.bringSubviewToFront(textMessage)
        scrollView.bringSubviewToFront(sendButton)
        did = CoreDID.getSelectedDID(moc)!.did
        textContacts.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model

        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.textContacts.resignFirstResponder()
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
  
        var msg : String = self.textMessage.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        self.textMessage.text = ""
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        var dateStr = formatter.stringFromDate(date)
        
        var contact = ""
        if selectedContact != "" {
            contact = selectedContact
        } else {
            contact = self.textContacts.text
        }
        
                //save to core data here
                CoreMessage.createInManagedObjectContext(self.moc, contact: contact, id: "", type: false, date: dateStr, message: msg, did: self.did, flag: message_status.DELIVERED.rawValue, completionHandler: { (responseObject, error) -> () in
                    if (CoreContact.currentContact(self.moc, contactId: contact) != nil) {
                        CoreContact.updateInManagedObjectContext(self.moc, contactId: contact, lastModified: dateStr)
                    } else {
                        CoreContact.createInManagedObjectContext(self.moc, contactId: contact, lastModified: dateStr)
                    }
                    
                    var cm = responseObject
                    Message.sendMessageAPI(contact, messageText: msg, did: self.did, completionHandler: { (responseObject, error) -> () in
                        if responseObject["status"].stringValue == "success" {
                            CoreMessage.deleteStaleMsgInManagedObjectContext(self.moc, coreId: cm!.coreId)
                        }
                    })
                    
                    //run the send message in the background

                    
                    
//                    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                    let controllerToPush: AnyObject! = storyBoard.instantiateViewControllerWithIdentifier("messageDetailView")
//                    self.navigationController?.setViewControllers([controllerToPush], animated: true)
                    self.delegate?.triggerSegue!(contact)
                    self.dismissViewControllerAnimated(false, completion: { () -> Void in
                    })
                    
                    
                })
//            } else {
//               // do something else
//            }
        
//        })
    }
    
  
    //MARK: - textView delegate methods
    
    func textViewDidChange(textView: UITextView) {
        
    }
    
    //MARK: - textField delegate methods
    
    
    func textFieldDidChange(textField: UITextField) {
        if textContacts.text != "" {
            
            CoreContact.getContacts(moc, did: did, dst: textContacts.text, name: nil, message: nil, completionHandler: { (responseObject, error) -> () in
                var coreContacts = responseObject as! [CoreContact]
                CoreContact.findAllContactsByName(self.moc, searchTerm: self.textContacts.text, existingContacts: coreContacts, completionHandler: { (contacts) -> () in
                    self.contacts = contacts!
                    self.tableView.reloadData()
                })
            })

        } else {
            self.contacts = [ContactStruct]()
            self.tableView.reloadData()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        var contact = self.contacts[indexPath.row]
         
        Contact().getContactsDict { (contacts) -> () in
            
            let contStr = contact.contactId as String
            if contacts[contact.contactId] != nil {
                cell.textLabel?.text = contacts[contact.contactId]
            } else {
                cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
            }
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //update text field to show contact
        self.selectedContact = self.contacts[indexPath.row].contactId
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        self.textContacts.text = cell?.textLabel?.text
        
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
            scrollView.contentInset = UIEdgeInsetsZero
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
                    offsetHeight = keyboardScreenEndFrame.height + 150
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
   
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetailSegue" {
            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            println(selectedContact)
            detailSegue.contactId = selectedContact
            detailSegue.did = did
        }
    }


}
