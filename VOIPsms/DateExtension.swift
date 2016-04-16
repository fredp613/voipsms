//
//  DateExtension.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-06-15.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation

extension NSDate
{
        func isGreaterThanDate(dateToCompare : NSDate) -> Bool
        {
            //Declare Variables
            var isGreater = false
            
            //Compare Values
            if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
            {
                isGreater = true
            }
            
            //Return Result
            return isGreater
        }
        
        
        func isLessThanDate(dateToCompare : NSDate) -> Bool
        {
            //Declare Variables
            var isLess = false
            
            //Compare Values
            if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
            {
                isLess = true
            }
            
            //Return Result
            return isLess
        }
    
       
        
        func today() -> Bool
        {
            
//            NSCalendar *cal = [NSCalendar currentCalendar];
//            NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
//            NSDate *today = [cal dateFromComponents:components];
//            components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:aDate];
//            NSDate *otherDate = [cal dateFromComponents:components];
            
            
            //Declare Variables
            var isEqualTo = false
            
            //Compare Values
            if self.compare(self) == NSComparisonResult.OrderedSame
            {
                isEqualTo = true
            }
            
            //Return Result
            return isEqualTo
        }
    
    
        func numberOfDaysUntilDateTime(toDateTime: NSDate, inTimeZone timeZone: NSTimeZone? = nil) -> Int {
            let calendar = NSCalendar.currentCalendar()
            if let timeZone = timeZone {
                calendar.timeZone = timeZone
            }
            
            var fromDate: NSDate?, toDate: NSDate?
            
            calendar.rangeOfUnit(.Day, startDate: &fromDate, interval: nil, forDate: self)
            calendar.rangeOfUnit(.Day, startDate: &toDate, interval: nil, forDate: toDateTime)
            
            let difference = calendar.components(.Day, fromDate: fromDate!, toDate: toDate!, options: [])
            return difference.day
        }
    
}