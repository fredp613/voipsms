//
//  ArrayExtension.swift
//  VOIPsms
//
//  Created by Fred Pearson on 2015-04-18.
//  Copyright (c) 2015 Frederick Pearson. All rights reserved.
//

import Foundation

extension Array {
    var last: T {
        return self[self.endIndex - 1]
    }
}