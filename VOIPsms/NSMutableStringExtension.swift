//
//  NSMutableStringExtension.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-07-17.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    public func setAsLink(textToFind:NSMutableAttributedString, linkURL: String?) -> Bool {
        let txtToManipulate = String("\(textToFind)")
        let foundRange = self.mutableString.rangeOfString(linkURL!)
        if foundRange.location != NSNotFound {
            print("found")
            self.addAttribute(NSLinkAttributeName, value: linkURL!, range: foundRange)
            return true
        }
        return false
    }
    
    public func setAsLinkFromResult(mutableString: NSMutableAttributedString, result: NSTextCheckingResult) {
//        if result.resultType == NSTextCheckingType.Link {
//            println(result.URL!)
//            println(result.range)
//            var textToEvaluate = NSString(string: "\(mutableStr)").substringWithRange(result.range)
//            //                mutableStr.setAsLink(mutableStr, linkURL: result.URL!.path!)
//            mutableStr.setAsLinkFromResult(mutableStr, result: NSTextCheckingResult)
//            
//            //                mutableStr.replaceCharactersInRange(result.range, withString: result.URL!.absoluteString!)
//            
//        }
        
        let txtToManipulate = NSString(string: "\(mutableString)")
        let foundRange = txtToManipulate.substringWithRange(result.range) as String
        print(foundRange)
        self.replaceCharactersInRange(result.range, withString: "booya")
        self.replaceCharactersInRange(result.range, withString: "asdfsdfsdffds")
//        self.addAttribute(NSLinkAttributeName, value: result.URL!.absoluteString!, range: result.range)
//        self.addAttribute(NSLinkAttributeName, value: result.URL!.absoluteString, range: foundRange)
    }
}