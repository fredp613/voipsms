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
    let moc : NSManagedObjectContext


    init(moc1: NSManagedObjectContext) {
        moc = moc1
    }
    
//    api_username={$user}&api_password={$pass}&method={$method}"
    
    func authenticatedUrl() -> String? {
        
        if let currentUser = CoreUser.currentUser(moc) {
            if let api_password = KeyChainHelper.retrieveForKey(currentUser.email) {
                let url = APIUrls.getUrl + "api_username=" + currentUser.email + "&api_password=" + api_password
                return url
            }
            return nil
        }
        return nil
    }
    
    func get_request_url_contruct(params: [String : String]?) -> String? {
        var url : String = ""
        
        if (params != nil) {

            if var url = authenticatedUrl() {
                url += "&"
                for (i, p) in (params!).enumerate() {
                    let lastIndexElement : Int = Int(params!.count - 1)
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
            url = authenticatedUrl()!
            return url
        }
                
    }
    
}