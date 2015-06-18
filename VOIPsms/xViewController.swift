//
//  xViewController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-16.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit

class xViewController: UIViewController {
        var contacts : [AddressBookContactStruct] = [AddressBookContactStruct]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contacts = Contact().getAllContacts(nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
