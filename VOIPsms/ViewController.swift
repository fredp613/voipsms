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
 
    @IBOutlet weak var textUserName: UITextView!
    
    @IBOutlet weak var textPwd: UITextView!
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textUserName.text = "hiphopshop@gmail.com"
        textPwd.text = "DPG613yg"
        loginBtn.layer.cornerRadius = 10
        

     
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWasPressed(sender: AnyObject) {
        self.loginBtn.setTitle("", forState: UIControlState.Normal)
        self.activityIndicator.startAnimating()
        CoreUser.authenticate(moc, email: self.textUserName.text, password: self.textPwd.text) { (success) -> Void in
            if success {
                let alert = UIAlertView(title: "Login successful", message: "Start sms'ing!!", delegate: self, cancelButtonTitle: nil)
                CoreDID.createOrUpdateDID(self.moc)
//                self.getInitialMessages()
                alert.show()
                self.activityIndicator.stopAnimating()
                if let currentUser = CoreUser.currentUser(self.moc) {
                    if currentUser.initialLogon.boolValue == true {
                        self.performSegueWithIdentifier("segueDownloadMessages", sender: self)
                    } else {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                }

//                self.dismissViewControllerAnimated(true, completion: nil)
                self.dismissAlert(alert)

            } else {
                self.activityIndicator.stopAnimating()
                self.loginBtn.setTitle("Sign in", forState: UIControlState.Normal)
                let alert = UIAlertView(title: "Invalid Login Credentials", message: "Please try again", delegate: self, cancelButtonTitle: "Ok")
                alert.show()
            }
        }
    }
    
    func getInitialMessages() {
        let fromStr = CoreDID.getSelectedDID(moc)!.registeredOn.strippedDateFromString()        
        Message.getMessagesFromAPI(false, moc: self.moc, from: fromStr, completionHandler: { (responseObject, error) -> () in
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueDownloadMessages") {
//          var dmvc = segue.destinationViewController as? DownloadMessagesViewController                
        }
    }
}

