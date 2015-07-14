//
//  TextFieldExtension.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-07-10.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation

//extension UITextField {
//    
//
//    
//}

class TextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: -25, bottom: 0, right: 0)
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return self.newBounds(bounds)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return self.newBounds(bounds)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return self.newBounds(bounds)
    }
    
    private func newBounds(bounds: CGRect) -> CGRect {
        var newBounds = bounds
        newBounds.origin.x += padding.left
        newBounds.origin.y += padding.top
        return newBounds
    }
    
}