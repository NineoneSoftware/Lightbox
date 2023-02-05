//
//  Collection+Extensions.swift
//  
//
//  Created by Joshua Russell on 2023-02-04.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
