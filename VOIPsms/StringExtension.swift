//
//  StringExtension.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-05-09.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation

extension String {
    
 
    func northAmericanPhoneNumberFormat() -> String {
       
        let strToFormat = self as NSString
        let areaCode = strToFormat.substringWithRange(NSRange(location: 0, length: 3))
        let firstPart = strToFormat.substringWithRange(NSRange(location: 3, length: 3))
        let lastPart = strToFormat.substringWithRange(NSRange(location: 6, length: 4))
        let formattedPhoneNumber = areaCode + "-" + firstPart + "-" + lastPart
        
        return formattedPhoneNumber
    }
    
}
