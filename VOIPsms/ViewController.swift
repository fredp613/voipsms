//
//  ViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UIAlertViewDelegate {
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var txtPwd: UITextField!

    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserName.text = "hiphopshop@gmail.com"
        txtPwd.text = "DPG613yg"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWasPressed(sender: AnyObject) {
        CoreUser.authenticate(moc, email: self.txtUserName.text, password: self.txtPwd.text) { (success) -> Void in
            if success {
                let alert = UIAlertView(title: "Login successful", message: "Start sms'ing!!", delegate: self, cancelButtonTitle: nil)
//                CoreDID.createOrUpdateDID(self.moc)
                alert.show()
                self.dismissViewControllerAnimated(true, completion: nil)
                self.dismissAlert(alert)
//                self.getInitialMessages()
            } else {
                let alert = UIAlertView(title: "Invalid Login Credentials", message: "Please try again", delegate: self, cancelButtonTitle: "Ok")
                alert.show()
            }
        }
    }
    
    func getInitialMessages() {
        Message.getMessagesFromAPI(self.moc, completionHandler: { (responseObject, error) -> () in
            if responseObject.count > 0 {
                println("success")
            } else {
                println("no messages yet")
            }
        })
    }
    
    func dismissAlert(alertView: UIAlertView) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), { () -> Void in
            sleep(1)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                alertView.dismissWithClickedButtonIndex(0, animated: true)
                
            })
        })
    }
    
    
    
    

}

