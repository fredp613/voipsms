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
    
    func strippedDateFromString() -> String {
        let strToFormat = self as NSString
        return strToFormat.substringWithRange(NSRange(location: 0, length: 10)) as String
    }
    
    func dateFormattedString() -> String {
        let tempDateFormatter = NSDateFormatter()
        tempDateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let tempDate = tempDateFormatter.dateFromString(self)
        
        let dateFormatterWeek = NSDateFormatter()
        dateFormatterWeek.dateFormat = "EEEE HH:mm:ss"
        
        let dateFormatterToday = NSDateFormatter()
        dateFormatterToday.dateFormat = "HH:mm:ss"
        
        let dateFormatterPast = NSDateFormatter()
        dateFormatterPast.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        
        let todaysDateFormmater = NSDateFormatter()
        todaysDateFormmater.dateFormat = "YYYY-MM-dd"
        let todaysDate = todaysDateFormmater.stringFromDate(NSDate())
        
        let messageDateFormatter = NSDateFormatter()
        messageDateFormatter.dateFormat = "YYYY-MM-dd"
        var messageDateToCompare = messageDateFormatter.stringFromDate(tempDate!)
        
        var finalDate = String()
        if todaysDate == messageDateToCompare {
            finalDate = "Today " + dateFormatterToday.stringFromDate(tempDate!)
        } else {
            
            var cleanDate1 = todaysDate.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            var cleanDate2 = messageDateToCompare.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            if cleanDate1.toInt()! - cleanDate2.toInt()! > 5 {
                finalDate = dateFormatterPast.stringFromDate(tempDate!)
            } else {
                finalDate = dateFormatterWeek.stringFromDate(tempDate!)
            }
            
        }
        return finalDate
    }
    
}
