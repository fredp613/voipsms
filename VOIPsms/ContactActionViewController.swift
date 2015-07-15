//
//  ContactActionViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-31.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData


protocol ContactActionViewControllerDelegate {
    func dismissContactActionVC()
}

class ContactActionViewController: UIViewController, ContactActionViewControllerDelegate {

    var contactId : String = String()
    var dismissFlag : Bool = false
    var moc : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        if dismissFlag {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissContactActionVC() {
        dismissFlag = true
    }
    

    @IBAction func cancelWasPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "createNewContactSegue") {
            var newContactSegue : NewContactViewController = segue.destinationViewController as! NewContactViewController
            newContactSegue.delegate = self
            newContactSegue.contactId = self.contactId
            newContactSegue.moc = self.moc
        }
        
        if (segue.identifier == "existingContactSegue") {
            var newExistingContactSegue : NewExistingContactViewController = segue.destinationViewController as! NewExistingContactViewController
            newExistingContactSegue.delegate = self
            newExistingContactSegue.contactId = self.contactId
            newExistingContactSegue.moc = self.moc
        }
    }


}
