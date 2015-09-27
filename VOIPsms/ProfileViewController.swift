//
//  ProfileViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-11.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    
    @IBOutlet weak var profileAccessSwitch: UISwitch!
    
    var addressBook = APAddressBook()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var alert = UIAlertView(title: "No contact access", message: "In order to sync your messages with your current contact(s) you must grant this application access with your contacts in your phone settings", delegate: self, cancelButtonTitle: "Ok")
        
        if Contact().checkAccess() {
            Contact().getContactsDict({ (contacts) -> () in

            })
        }
        
        
        profileAccessSwitch.addTarget(self, action: "toggleProfileSwitch:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Do any additional setup after loading the view.
    }
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        let regex = try! NSRegularExpression(pattern: regex,
            options: [])
        let nsString = text as NSString
        let results = regex.matchesInString(text,
            options: [], range: NSMakeRange(0, nsString.length))
            
        return results.map { nsString.substringWithRange($0.range)}
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Switch Events
    func toggleProfileSwitch(sender: UISwitch) {
        if profileAccessSwitch.on {
            
        } else {
            print("off")
        }
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
