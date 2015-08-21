//
//  Array+removeObject.swift
//  bonjour-demo-mac
//
//  Created by James Zaghini on 12/05/2015.
//  Copyright (c) 2015 James Zaghini. All rights reserved.
//

extension Array {
    mutating func removeObject<U: Equatable>(object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerate() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                }
            }
        }
        
        if(index != nil) {
            self.removeAtIndex(index!)
        }
    }
}