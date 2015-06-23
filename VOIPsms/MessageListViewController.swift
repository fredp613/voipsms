//
//  MessageListViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class MessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var did : String = String()
    var titleBtn: UIButton = UIButton()
    var timer : NSTimer = NSTimer()
    var managedObjectContext : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreContact")
        let primarySortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
//        contactsFetchRequest.fetchLimit = 10
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    
    lazy var searchFetchedResultsController: NSFetchedResultsController = {
        let contactsFetchRequest = NSFetchRequest(entityName: "CoreContact")
        let primarySortDescriptor = NSSortDescriptor(key: "lastModified", ascending: false)
        contactsFetchRequest.sortDescriptors = [primarySortDescriptor]
        let frc = NSFetchedResultsController(
            fetchRequest: contactsFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error)==false) {
            println("An error has occurred: \(error?.localizedDescription)")
        }
        if let testArr = fetchedResultsController.fetchedObjects {
            var t = NSArray(array: testArr)
            let predicate = NSPredicate(format: "contactId contains[cd] %@", "613")
            var results = t.filteredArrayUsingPredicate(predicate)
            println("results are \(results)")
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        titleBtn = UIButton(frame: CGRectMake(navigationController!.navigationBar.center.x, navigationController!.navigationBar.center.y, 100, 40))
        if let selectedDID = CoreDID.getSelectedDID(managedObjectContext) {
            self.did = selectedDID.did
            titleBtn.setTitle(self.did.northAmericanPhoneNumberFormat(), forState: UIControlState.Normal)
            titleBtn.addTarget(self, action: Selector("titleClicked:"), forControlEvents: UIControlEvents.TouchUpInside)
            titleBtn.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
            self.navigationController?.navigationBar.topItem?.titleView = titleBtn
        }
        
        startTimer()
    }
    
    func startTimer() {
        if Reachability.isConnectedToNetwork() {
            timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func timerDidFire(sender: NSTimer) {
        if let str = CoreDID.getSelectedDID(managedObjectContext) {
            let fromStr = CoreMessage.getLastMsgByDID(managedObjectContext, did: did)?.date.strippedDateFromString()
            if fromStr == nil {
                println("nil from string")
            } else {
                Message.getMessagesFromAPI(false, moc: managedObjectContext, from: fromStr, completionHandler: { (responseObject, error) -> () in
                    self.tableView.reloadData()
                })
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Core Data Delegates
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case .Update:
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        default:
            println("problem")
            self.tableView.reloadData()
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    //MARK: table view delegates
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
//            println(sections.count)
            return 1
            //use the below for sections - look at sectionkeynamepath in the fetchedresultscontroller to create sections
//            return sections.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        

        

        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let contact = fetchedResultsController.objectAtIndexPath(indexPath) as! CoreContact
        
        let primarySortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        var sortedMessages = contact.messages.sortedArrayUsingDescriptors([primarySortDescriptor])
        var message: CoreMessage = sortedMessages.first! as! CoreMessage
        cell.textLabel?.text = "\(contact.contactId.northAmericanPhoneNumberFormat())" //+ "-" + (message.date as String)
        
       cell.detailTextLabel?.text = message.message
        
        if message.type == true || message.type == 1 {
            if message.flag == message_status.PENDING.rawValue {
                cell.textLabel?.textColor = UIColor(red: 220/255, green: 170/255, blue: 11/255, alpha: 1)
                cell.detailTextLabel?.textColor = UIColor(red: 220/255, green: 170/255, blue: 77/255, alpha: 1)
            } else {
                cell.textLabel?.textColor = UIColor.blackColor()
                cell.detailTextLabel?.textColor = UIColor.blackColor()
            }
        } else {
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.detailTextLabel?.textColor = UIColor.blackColor()
        }
        
        let font:UIFont? = UIFont(name: "Arial", size: 13.0)
        let dateStr = NSAttributedString(string: message.date.dateFormattedString(), attributes:
            [NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                NSFontAttributeName: font!])
        let dateFrame = CGRectMake(cell.frame.origin.x, cell.detailTextLabel!.frame.origin.x, cell.frame.width - 30, cell.textLabel!.frame.height)
        let dateLbl = UILabel(frame: dateFrame)
        dateLbl.attributedText = dateStr
        dateLbl.textAlignment = NSTextAlignment.Right
        dateLbl.tag = 3
        
        if cell.contentView.viewWithTag(3) != nil {
            cell.contentView.viewWithTag(3)?.removeFromSuperview()
        }
        cell.contentView.addSubview(dateLbl)
        
        return cell
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
