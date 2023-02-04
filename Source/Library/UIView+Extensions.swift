//
//  UIView+Extensions.swift
//  Lightbox-iOS
//
//  Created by Joshua Russell on 2023-02-01.
//  Copyright © 2023 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

internal extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle.module.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
