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
        textUserName.text = "fredp613@gmail.com"
        textPwd.text = "Fredp613$"
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
        self.login()
    }
    
    func login() {
        CoreUser.authenticate(moc, email: self.textUserName.text, password: self.textPwd.text) { (success, error) -> Void in
            if error == nil {
                if success {
                    let alert = UIAlertView(title: "Login successful", message: "Checking for messages", delegate: self, cancelButtonTitle: nil)
//                    CoreDID.createOrUpdateDID(self.moc)
                    alert.show()
                    self.activityIndicator.stopAnimating()
                    if let currentUser = CoreUser.currentUser(self.moc) {
                        if currentUser.initialLogon.boolValue == true {
                            self.performSegueWithIdentifier("segueDownloadMessages", sender: self)                                                      
                            if let device = CoreDevice.getToken(self.moc) {
                                var tk = device.deviceToken
                                self.sendDeviceDetailsToAPI(tk, user: currentUser)
                            }

                        } else {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                    self.dismissAlert(alert)
                    
                } else {
                    self.activityIndicator.stopAnimating()
                    self.loginBtn.setTitle("Sign in", forState: UIControlState.Normal)
                    let alert = UIAlertView(title: "Invalid Login Credentials", message: "Please try again", delegate: self, cancelButtonTitle: "Ok")
                    alert.show()
                }
            } else {
                self.showErrorController()
            }
        }
    }
    
    func showErrorController() {
        var alertController = UIAlertController(title: "Network Error", message: "We are having trouble reaching the voip.ms servers, click Ok to try again or No to cancel to try again later", preferredStyle: .Alert)
        
        var okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            println("pressed")
            self.login()
        }
        var cancelAction = UIAlertAction(title: "No, cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            println("cancelled")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func getInitialMessages() {
        let fromStr = CoreDID.getSelectedDID(moc)!.registeredOn.strippedDateFromString()        
        Message.getMessagesFromAPI(false, fromList: false, moc: self.moc, from: fromStr, completionHandler: { (responseObject, error) -> () in
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
    
    
    func sendDeviceDetailsToAPI(deviceId: String, user: CoreUser) {
        
        
        
        if let did = CoreDID.getSelectedDID(self.moc) {
            if let api_password = KeyChainHelper.retrieveForKey(user.email) {
                let params = [
                    "user":[
                        "email": "fredp613@gmail.com",
                        "pwd": api_password,
                        "did":did.did,
                        "device": deviceId
                    ]
                ]
                var url = "http://localhost:3000/users"
//                params should go in body of request

                VoipAPI(httpMethod: httpMethodEnum.POST, url: url, params: params).APIAuthenticatedRequest({ (responseObject, error) -> () in
                    println(responseObject)
                })
            }
        }
//        email: {type: String, required: true},
//        password: { type: String, required: true },
//        did: {type: String, required: true},
//        device_token: { type: String, required: true },
    }
    
    //MARK: TextField Delegates


    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueDownloadMessages") {
//          var dmvc = segue.destinationViewController as? DownloadMessagesViewController                
        }
    }
}

