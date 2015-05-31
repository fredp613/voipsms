//
//  ViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UIAlertViewDelegate, MessageViewDelegate {
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var txtPwd: UITextField!
    @IBOutlet weak var loginBtn: UIButton!

    var moc : NSManagedObjectContext = CoreDataStack().managedObjectContext!
    var delegate: MessageViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserName.text = "hiphopshop@gmail.com"
        txtPwd.text = "DPG613yg"
        loginBtn.layer.cornerRadius = 10

     
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func updateMessagesTableView() {
        //soemthing
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginWasPressed(sender: AnyObject) {
        CoreUser.authenticate(moc, email: self.txtUserName.text, password: self.txtPwd.text) { (success) -> Void in
            if success {
                let alert = UIAlertView(title: "Login successful", message: "Start sms'ing!!", delegate: self, cancelButtonTitle: nil)
                CoreDID.createOrUpdateDID(self.moc)
//                self.getInitialMessages()
                alert.show()
                self.dismissViewControllerAnimated(true, completion: nil)
                self.dismissAlert(alert)
                self.delegate?.updateMessagesTableView!()

            } else {
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
    
    
    
    

}

