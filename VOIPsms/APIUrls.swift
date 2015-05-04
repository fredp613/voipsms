//
//  APIUrls.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-12.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation
import CoreData


class APIUrls {
    
    static let getUrl = "https://voip.ms/api/v1/rest.php?"
    var moc : NSManagedObjectContext
    
    init() {
        moc = CoreDataStack().managedObjectContext!
    }
    
    
//    api_username={$user}&api_password={$pass}&method={$method}"
    
    class func authenticatedUrl() -> String? {
        let moc1 = CoreDataStack().managedObjectContext!
        if let currentUser = CoreUser.currentUser(moc1) {
            if let api_password = KeyChainHelper.retrieveForKey(currentUser.email) {
                var url = APIUrls.getUrl + "api_username=" + currentUser.email + "&api_password=" + api_password
                return url
            }
            return nil
        }
        return nil
    }
    
    
    class func get_request_url_contruct(params: [String : String]?) -> String? {
        var url : String = ""
        
        if (params != nil) {

            if var url = APIUrls.authenticatedUrl() {
                url += "&"
                for (i, p) in enumerate(params!) {
                    var lastIndexElement : Int = Int(params!.count - 1)
                    if lastIndexElement == 0 {
                       url += (p.0 + "=" + p.1)
                    } else {
                        if i == lastIndexElement {
                            url += (p.0 + "=" + p.1)
                        } else {
                            url
                                += (p.0 + "=" + p.1 + "&")
                        }
                    }
                    
                }
                
                return url
            }
            return nil
        
        } else {
            url = APIUrls.authenticatedUrl()!
            return url
        }
                
    }
    
}