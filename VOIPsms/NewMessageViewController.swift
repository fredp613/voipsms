//
//  NewMessageViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-03.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit

class NewMessageViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate {
    @IBOutlet weak var textContacts: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessage: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableViewHeighConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    
    let addressBook = APAddressBook()
    var model = ModelSize()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.textMessage.delegate = self
        self.scrollView.delegate = self
        
//        dispatch_async(dispatch_get_current_queue(), ^{
//    a        [self.usernameInputField becomeFirstResponder];
//            });
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("adjustForKeyboard:"), name: UIKeyboardWillShowNotification, object: nil)
//        self.textMessage.becomeFirstResponder()
//        self.textContacts.becomeFirstResponder()
        scrollView.bounces = false
        scrollView.bringSubviewToFront(tableView)
        scrollView.bringSubviewToFront(textMessage)
        scrollView.bringSubviewToFront(sendButton)
        
        let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height
        model = IOSModel(screen: screenHeight).model
       
    }
    
    
    
    override func viewWillDisappear(animated: Bool) {
        self.textMessage.resignFirstResponder()
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addContactWasPressed(sender: AnyObject) {
    }

    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func sendMessageWasPressed(sender: AnyObject) {
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
        
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //update text field to show contact
    }
    
    //MARK: - Keyboard delegates
    
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
            if notification.name == UIKeyboardWillShowNotification {
                if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                    self.tableViewHeighConstraint.constant = IOSModel(model: self.model).compressedHeight
                    let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
                    scrollView.contentInset = contentInsets;
                }
            }
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
