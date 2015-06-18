//
//  NewExistingContactViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-31.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class NewExistingContactViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UITableViewDataSource, ContactActionViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var contacts : [AddressBookContactStruct] = [AddressBookContactStruct]()
    var contactId : String = String()
    var delegate: ContactActionViewControllerDelegate? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.searchBar.delegate = self
        self.contacts = Contact().getAllContacts(nil)
        
//        Contact().getContactsTest("", completionHandler: { (contacts) -> () in
//            self.contacts = contacts!
//            self.tableView.reloadData()
//        })
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.searchBar.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        cell.textLabel?.text = contact.contactFullName //+ "-" + contact.recordId
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if Contact().addPhoneToExistingContact(self.contacts[indexPath.row].recordId, phone: self.contactId) {
            println("all good")
        }
        var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to add \(self.contactId.northAmericanPhoneNumberFormat()) to this contact: \(self.contacts[indexPath.row].contactFullName)", preferredStyle: .Alert)
        
        var okAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            println("pressed")

            self.dismissContactActionVC()
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
            })
        }
        var cancelAction = UIAlertAction(title: "No, cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            println("cancelled")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func dismissContactActionVC() {
        delegate?.dismissContactActionVC()
    }
    
    //MARK: - Searchbar delegate methods
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text != "" {
//            self.contacts = Contact().getAllContacts(searchBar.text)
        } else {
//            self.contacts = Contact().getAllContacts(nil)
        }
        self.tableView.reloadData()        
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        self.contacts = Contact().getAllContacts(nil)
        searchBar.resignFirstResponder()
    }


    
    //MARK: - Keyboard delegates
    
//    func keyboardWillHide(sender: NSNotification) {
//        let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
//        scrollView.contentInset = contentInsets;
//        scrollView.scrollIndicatorInsets = contentInsets;
//        //        self.textContacts.becomeFirstResponder()
//    }
//    
//    func adjustForKeyboard(notification: NSNotification) {
//        
//        let userInfo = notification.userInfo!
//        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
//        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
//        
//        if notification.name == UIKeyboardWillHideNotification {
//            scrollView.contentInset = UIEdgeInsetsZero
//        } else {
//            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
//                if notification.name == UIKeyboardWillChangeFrameNotification {
//                    self.tableViewHeighConstraint.constant = compressedTableViewHeight - (keyboardViewEndFrame.height) - 30
//                    let contentInsets : UIEdgeInsets = UIEdgeInsetsZero;
//                    scrollView.contentInset = contentInsets;
//                }
//            }
//        }
//    }


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
