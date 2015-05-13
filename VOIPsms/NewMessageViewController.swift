//
//  NewMessageViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-03.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit

class NewMessageViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var textContacts: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessage: UITextField!
    let addressBook = APAddressBook()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.textMessage.delegate = self
        
//        dispatch_async(dispatch_get_current_queue(), ^{
//    a        [self.usernameInputField becomeFirstResponder];
//            });
        self.textContacts.becomeFirstResponder()
       
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
