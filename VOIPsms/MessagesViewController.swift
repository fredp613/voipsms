//
//  MessagesViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-16.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore

protocol UpdateMessagesTableViewDelegate {
    func updateMessagesTableView()
}


class MessagesViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UpdateMessagesTableViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarTextField: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var contacts : [CoreContact] = [CoreContact]()
    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var maskView : UIView = UIView()
    var timer : NSTimer = NSTimer()
    var did : String = String()
    var didView : UIPickerView = UIPickerView()
    var titleBtn : UIButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        
//        viewSetup()
        startTimer()
    }
    
    func updateMessagesTableView() {
        println("delegate called")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        titleBtn = UIButton(frame: CGRectMake(0, 0, 100, 40))
        if let selectedDID = CoreDID.getSelectedDID(moc) {
            self.did = selectedDID.did
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            titleBtn.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
            titleBtn.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.navigationController?.navigationBar.topItem?.titleView = titleBtn
        }

        self.activityIndicator.startAnimating()
        viewSetup()
//        timer.invalidate()
        
        if self.searchBar.text != "" {
            self.search(self.searchBar.text)
            self.searchBar.becomeFirstResponder()
        }
        startTimer()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        
    }
    
    func viewSetup() {
        if CoreUser.userExists(moc) {
            var searchTerm = self.searchBar.text
            CoreContact.getContacts(moc, did: did, dst: searchTerm, name: searchTerm, message: searchTerm, completionHandler: { (responseObject, error) -> () in
                self.contacts = responseObject as! [CoreContact]
                CoreContact.findByName(self.moc, searchTerm: searchTerm, existingContacts: self.contacts, completionHandler: { (contacts) -> () in
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.contacts = contacts!
                        self.activityIndicator.stopAnimating()
//                        self.tableView.reloadData()
//                    })
                })
            })
        }
        self.tableView.reloadData()
    }
    
    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
    }
    
    func timerDidFire(sender: NSTimer) {
        var initialMessageCount = CoreMessage.getMessages(moc, ascending: false).count
        if CoreUser.userExists(moc) {
            if let str = CoreDID.getSelectedDID(moc) {
                let fromStr = CoreMessage.getLastMsgByDID(moc, did: did)?.date.strippedDateFromString()
                if fromStr == nil && self.contacts.count > 0 {
                    self.activityIndicator.startAnimating()
                }
                Message.getMessagesFromAPI(self.moc, from: fromStr, completionHandler: { (responseObject, error) -> () in
                    if responseObject.count > 0 {
                        CoreContact.getContacts(self.moc, did: self.did, dst: self.searchBar.text, name: self.searchBar.text, message: self.searchBar.text, completionHandler: { (responseObject, error) -> () in
                            self.contacts = responseObject as! [CoreContact]
                            CoreContact.findByName(self.moc, searchTerm: self.searchBar.text, existingContacts: self.contacts, completionHandler: { (contacts) -> () in
                                
                                var newMessageCount = CoreMessage.getMessages(self.moc, ascending: false).count
                                if initialMessageCount < newMessageCount {
//                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.contacts = contacts!
                                        let indexSet = NSIndexSet(index: 0)
                                        self.tableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.None)
//                                    })
                                }
                                self.activityIndicator.stopAnimating()
                            })
                        })
                        
                    } else {
                        println("no messages yet")
                    }
                })
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell    
        var contact = self.contacts[indexPath.row]
        
        //if not and existing contact from contacts - format
        var contactName = String()
        Contact().getContactsDict { (contacts) -> () in

            let contStr = contact.contactId as String
            if contacts[contact.contactId] != nil {
               cell.textLabel?.text = contacts[contact.contactId]
            } else {
               cell.textLabel?.text = contact.contactId.northAmericanPhoneNumberFormat()
            }
        }
        
        
        
        //if existing contact : cell... = contact.full_name
        
        if let lastMessage = CoreContact.getLastMessageFromContact(moc, contactId: contact.contactId, did: did) {
            cell.detailTextLabel?.text = "\(lastMessage.message)"
            if lastMessage.type == true || lastMessage.type == 1 {
                if lastMessage.flag == message_status.PENDING.rawValue {
                    cell.detailTextLabel?.textColor = UIColor.blueColor()
                } else {
                    cell.detailTextLabel?.textColor = UIColor.blackColor()
                }
            } else {
                cell.detailTextLabel?.textColor = UIColor.blackColor()
            }

        }
        
        return cell

    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPth: NSIndexPath) -> Bool {
        return true
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.timer.invalidate()
        
        if editingStyle == UITableViewCellEditingStyle.Delete {

            let contactId = contacts[indexPath.row].contactId
            var ids = CoreContact.getMsgsByContact(moc, contactId: contactId, did: self.did).map {$0.id}

            CoreMessage.deleteAllMessagesFromContact(moc, contactId: contactId, did: self.did, completionHandler: { (responseObject, error) -> () in
                
                CoreContact.getContacts(self.moc, did: self.did, dst: self.searchBar.text, name: self.searchBar.text, message:
                    self.searchBar.text, completionHandler: { (responseObject, error) -> () in
                        
                        CoreContact.findByName(self.moc, searchTerm: "", existingContacts: self.contacts, completionHandler: { (contacts) -> () in
                            self.contacts = responseObject as! [CoreContact]
                            self.tableView.beginUpdates()
                            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                            self.tableView.endUpdates()
                            self.startTimer()

                        })
                })

                Message.deleteMessagesFromAPI(ids, completionHandler: { (responseObject, error) -> () in
                    if responseObject {
                        println("something went right :)")
                    } else {
                        println("something went wrong")
                    }
                })

            })
            println("deleting")
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier("showMessagesSegue", sender: self)
//        })
    }
    
    //MARK: - Button Events
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
        if let coreDids = CoreDID.getDIDs(self.moc) {
//            coreDids.filter() { $0.did == self.did }
            for c in coreDids {
                didArr.append(c.did)
            }
        }
        let currentDIDIndex = find(didArr, self.did)
        didView.selectRow(currentDIDIndex!, inComponent: 0, animated: false)
        drawMaskView()
        self.view.addSubview(didView)

    }
    
    //MARK: - PickerView delegate methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CoreDID.getDIDs(self.moc)!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        let formattedDID = CoreDID.getDIDs(self.moc)![row].did.northAmericanPhoneNumberFormat()
        return formattedDID
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if let dids = CoreDID.getDIDs(self.moc) {
            self.did = dids[row].did
            CoreDID.toggleSelected(moc, did: self.did)
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            viewSetup()
        }
        didView.removeFromSuperview()
        maskView.removeFromSuperview()
    }
    
    //MARK: - Searchbar delegate methods
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        clearSearch()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()
        didView.removeFromSuperview()

    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        drawMaskView()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.search(searchText)
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        if self.searchBar.text == "" || self.searchBar.text == nil {
            clearSearch()
        }
        return true
    }
    
    func drawMaskView() {
        maskView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y - 75, self.tableView.frame.width, self.tableView.frame.height)
        maskView.backgroundColor = UIColor(white: 0.98, alpha: 0.8)
        maskView.bounds = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.width, tableView.frame.height)//- (searchBar.frame.height * 2) - 60)
        maskView.center = self.tableView.center
        self.view.addSubview(maskView)
    }
    
    func clearSearch() {
        self.searchBar.text = ""
        searchBar.resignFirstResponder()
        maskView.removeFromSuperview()

        CoreContact.getContacts(moc, did: did, dst: nil, name: nil, message: nil) { (responseObject, error) -> () in
            CoreContact.findByName(self.moc, searchTerm: "", existingContacts: self.contacts, completionHandler: { (contacts) -> () in
                self.contacts = responseObject as! [CoreContact]
                self.tableView.reloadData()
            })
        }
    
        startTimer()
    }
    
    func search(searchTerm: String) {
//        timer.invalidate()
        if count(searchTerm) > 0 {
//            CoreContact.getContacts(moc, did: did, dst: searchTerm, name: searchTerm, message: searchTerm) { (responseObject, error) -> () in
//                self.contacts = responseObject as! [CoreContact]
//                self.tableView.reloadData()
//            }
            
            CoreContact.getContacts(moc, did: did, dst: searchTerm, name: searchTerm, message: searchTerm, completionHandler: { (responseObject, error) -> () in
                self.contacts = responseObject as! [CoreContact]
                CoreContact.findByName(self.moc, searchTerm: searchTerm, existingContacts: self.contacts, completionHandler: { (contacts) -> () in
                    self.contacts = contacts!
                    self.tableView.reloadData()
                })
            })

        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showMessagesSegue") {

            var detailSegue : MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
            let path = self.tableView.indexPathForSelectedRow()

            var contactId = self.contacts[path!.row].contactId
            detailSegue.did = self.did
            detailSegue.contactId = contactId
            timer.invalidate()
            
            
        }
        
       
    }
    

}
