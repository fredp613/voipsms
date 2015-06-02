//
//  NewContactViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-31.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit

class NewContactViewController: UIViewController, UITextFieldDelegate, ContactActionViewControllerDelegate {

    @IBOutlet weak var textFirstName: UITextField!
    @IBOutlet weak var textLastName: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textMobile: UITextField!
    var delegate: ContactActionViewControllerDelegate? = nil
    
    var contactId : String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textFirstName.delegate = self
        self.textLastName.delegate = self
        self.textMobile.delegate = self
        self.textMobile.text = contactId.northAmericanPhoneNumberFormat()
        self.textFirstName.addTarget(self, action: "textFieldChange:", forControlEvents: UIControlEvents.EditingChanged)
        self.textLastName.addTarget(self, action: "textFieldChange:", forControlEvents: UIControlEvents.EditingChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.textFirstName.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.textFirstName.resignFirstResponder()
        self.textLastName.resignFirstResponder()
        self.textMobile.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func triggerSegue(contact: String) {
        //do something
    }
    
    //MARK: - Buton Actions
    
    @IBAction func doneWasPressed(sender: AnyObject) {
        if self.textFirstName.text != "" {
            Contact().createContact(contactId, firstName: self.textFirstName.text, lastName: self.textLastName.text)
            self.dismissContactActionVC()
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
            })
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func dismissContactActionVC() {
        delegate?.dismissContactActionVC()
    }
    
    //MARK: - text field delegates
    
    func textFieldChange(sender: UITextField) {
        if self.textFirstName.text != "" {
            self.doneButton.setTitle("Done", forState: UIControlState.Normal)
        } else {
            self.doneButton.setTitle("Cancel", forState: UIControlState.Normal)
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
//        createNewContactSegue
    }


}
