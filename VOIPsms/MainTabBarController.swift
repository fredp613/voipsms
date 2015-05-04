//
//  MainTabBarController.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-13.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import UIKit
import CoreData

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    var moc: NSManagedObjectContext = CoreDataStack().managedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        
        if CoreUser.userExists(moc)  {
            let currentUser = CoreUser.currentUser(moc)
            let pwd = KeyChainHelper.retrieveForKey(currentUser!.email)
            
            CoreUser.authenticate(moc, email: currentUser!.email, password: pwd!, completionHandler: { (success) -> Void in
                if success == false || currentUser?.remember == false {
                    self.performSegueWithIdentifier("showLoginSegue", sender: self)
                }
            })
        } else {
            performSegueWithIdentifier("showLoginSegue", sender: self)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

//        switch tabBarController.selectedIndex {
//            case 0: navigationController?.navigationBar.topItem?.title = "Messages"
//            default: navigationController?.navigationBar.topItem?.title = "Profile"
//        }
        

    }
    
    
    @IBAction func logoutWasPressed(sender: AnyObject) {
        let currentUser = CoreUser.currentUser(moc)
        
        CoreUser.logoutUser(moc, coreUser: currentUser!)
        self.performSegueWithIdentifier("showLoginSegue", sender: self)

    }
    
    @IBAction func newMessageWasClicked(sender: AnyObject) {
//        self.performSegueWithIdentifier("newMessageSegue", sender: self)
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
