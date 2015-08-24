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
        let regex = NSRegularExpression(pattern: "[0-9]", options: nil, error: nil)
        if (regex?.matchesInString(self, options: nil, range: NSMakeRange(0, strToFormat.length)) != nil) {
            if strToFormat.length > 9 {
                let areaCode = strToFormat.substringWithRange(NSRange(location: 0, length: 3))
                let firstPart = strToFormat.substringWithRange(NSRange(location: 3, length: 3))
                let lastPart = strToFormat.substringWithRange(NSRange(location: 6, length: 4))
                let formattedPhoneNumber = areaCode + "-" + firstPart + "-" + lastPart
                
                return formattedPhoneNumber
            }
        }
        return self
        
    }
    
    func strippedDateFromString() -> String {
        let strToFormat = self as NSString
        return strToFormat.substringWithRange(NSRange(location: 0, length: 10)) as String
    }
    
    func removeSpaces() -> String {
        var str = self.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        var str1 = str.stringByReplacingOccurrencesOfString("-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        var final = str1.stringByReplacingOccurrencesOfString(":", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        return final
    }
    
    func truncatedString() -> String {
        if count(self) > 15 {
            //truncate
            var firstPart = self.substringToIndex(advance(self.startIndex, 23))
            var truncateIndicator = "..."
            return firstPart + truncateIndicator
        }
        return self
    
    }
    
    func dateFormattedString() -> String {
        let tempDateFormatter = NSDateFormatter()
        tempDateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let tempDate = tempDateFormatter.dateFromString(self)
        
        let dateFormatterWeek = NSDateFormatter()
        dateFormatterWeek.dateFormat = "EEEE HH:mm"
        
        let dateFormatterToday = NSDateFormatter()
        dateFormatterToday.dateFormat = "HH:mm"
        
        let dateFormatterPast = NSDateFormatter()
        dateFormatterPast.dateFormat = "YYYY-MM-dd HH:mm"
                
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
