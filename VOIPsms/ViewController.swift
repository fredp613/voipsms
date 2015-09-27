//
//  ViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController, UIAlertViewDelegate, UITextFieldDelegate {
     
    @IBOutlet weak var textPwd: TextField!
    @IBOutlet weak var textUserName: TextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textUserName.delegate = self
        textPwd.delegate = self
//        textUserName.text = "fredp613@gmail.com"
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
       
        if self.textPwd.text != "" && self.textUserName != nil {
            self.loginBtn.setTitle("", forState: UIControlState.Normal)
            self.activityIndicator.startAnimating()
            self.login()
        } else {
            let alert = UIAlertView(title: "Credentials Error", message: "User name and/or password cannot be blank", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
        }
        
    }
    
    @IBAction func goBackPressed(sender: AnyObject) {
//        self.performSegueWithIdentifier("showWizard", sender: self)
        navigationController?.popViewControllerAnimated(true)
//        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func login() {
        CoreUser.authenticate(moc, email: self.textUserName.text!, password: self.textPwd.text!) { (success, error, status) -> Void in
            if error == nil {
                if success {
                    let alert = UIAlertView(title: "Login successful", message: "Checking for messages", delegate: self, cancelButtonTitle: nil)
//                    CoreDID.createOrUpdateDID(self.moc)
                    alert.show()
                    self.activityIndicator.stopAnimating()
                    if let currentUser = CoreUser.currentUser(self.moc) {
                        if currentUser.initialLogon.boolValue == true {
                            self.performSegueWithIdentifier("segueDownloadMessages", sender: self)
                        } else {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                    self.dismissAlert(alert)
                    
                } else {
                    self.activityIndicator.stopAnimating()
                    self.loginBtn.setTitle("Sign in", forState: UIControlState.Normal)
                    var messageTitle : String = ""
                    if status == "api not enabled" {
                        messageTitle = "API not enabled"
                    } else {
                        messageTitle = "Invalid login credentials"
                    }

                    let alert = UIAlertView(title: messageTitle, message: "Please try again", delegate: self, cancelButtonTitle: "Ok")
                    alert.show()
                }
            } else {
                self.showErrorController()
            }
        }
    }
    
    func showErrorController() {
        let alertController = UIAlertController(title: "Network Error", message: "We are having trouble reaching the voip.ms servers, click Ok to try again or No to cancel to try again later", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            print("pressed")
            self.login()
        }
        let cancelAction = UIAlertAction(title: "No, cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            print("cancelled")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func getInitialMessages() {
        let fromStr = CoreDID.getSelectedDID(moc)!.registeredOn.strippedDateFromString()        
        Message.getMessagesFromAPI(false, fromList: false, moc: self.moc, from: fromStr, completionHandler: { (responseObject, error) -> () in
            if responseObject.count > 0 {
                print("success")
            } else {
                print("no messages yet")
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
    
    
   
    
    //MARK: TextField Delegates


    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueDownloadMessages") {
//          var dmvc = segue.destinationViewController as? DownloadMessagesViewController                
        }
    }
}

