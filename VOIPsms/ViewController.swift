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

    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).moc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textUserName.delegate = self
        textPwd.delegate = self
        loginBtn.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true;
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
//        testAPI()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        testAPI();
        return true;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWasPressed(sender: AnyObject) {
//        testAPI()
        
        if let userName : String = self.textUserName.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) {
            if userName != "" {

                if self.textPwd.text != "" {
                    self.loginBtn.setTitle("", forState: UIControlState.Normal)
                    self.activityIndicator.startAnimating()
                    self.login()
                } else {
                    let alert = UIAlertView(title: "Credentials Error", message: "User name and/or password cannot be blank", delegate: self, cancelButtonTitle: "Ok")
                    alert.show()
                }
            } else {
                let alert = UIAlertView(title: "Email error", message: "Please enter a valid email address", delegate: self, cancelButtonTitle: "Ok")
                alert.show()
                print("\(userName)".isEmail())
            }
            
        
        } else {
            let alert = UIAlertView(title: "Something went wrong", message: "Please enter a valid email address", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
            
        }
        
        
        
    }
    
    func login() {
       // testAPI()
        let userName : String = self.textUserName.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        
        if Reachability.isConnectedToNetwork() {
            CoreUser.authenticate(moc, email: userName, password: self.textPwd.text!) { (success, error, status) -> Void in
                
                if error == nil {
                    if success {

//                        CoreDID.createOrUpdateDID(self.moc)
                        
                        let alert = UIAlertView(title: "Login successful", message: "Checking for messages", delegate: self, cancelButtonTitle: nil)
                        alert.show()
                        self.activityIndicator.stopAnimating()
                        if let currentUser = CoreUser.currentUser(self.moc) {
                            if currentUser.initialLogon.boolValue == true {
                                self.performSegueWithIdentifier("segueDownloadMessages", sender: self)
//                                self.performSegueWithIdentifier("segueToMessages", sender: self)
                            } else {
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        }
                        self.dismissAlert(alert)
                        
                    } else {
                        self.activityIndicator.stopAnimating()
                        self.loginBtn.setTitle("Sign in", forState: UIControlState.Normal)
                        var messageTitle : String = ""
                        var messageDesc : String = ""
                        if status == "api not enabled" {
                            messageTitle = "API not enabled"
                            messageDesc = "Please go to your account settings and turn on the enable api option. Also ensure to insert 0.0.0.0 in the allowed IP section"
                        } else {
                            print(status)
                            messageTitle = "Invalid login credentials"
                            messageDesc = ""
                        }
                        
                        let alert = UIAlertView(title: messageTitle, message: messageDesc, delegate: self, cancelButtonTitle: "Ok")
                        alert.show()
                    }
                } else {
                    self.loginBtn.setTitle("Sign In", forState: UIControlState.Normal)
                    self.activityIndicator.stopAnimating()
                    self.showErrorController()
                }
            }
        } else {
            self.loginBtn.setTitle("Sign In", forState: UIControlState.Normal)
            self.activityIndicator.stopAnimating()
            let alert = UIAlertView(title: "Not connected to the internet", message: "Please verify that you are on a working wifi or mobile connection", delegate: self, cancelButtonTitle: "Ok")
            alert.show()
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
            self.textPwd.resignFirstResponder()
//          var dmvc = segue.destinationViewController as? DownloadMessagesViewController                
        }
    }
}

