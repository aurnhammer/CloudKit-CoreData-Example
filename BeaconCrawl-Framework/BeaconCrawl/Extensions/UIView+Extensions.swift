//
//  UIView+Extensions.swift
//  GKSessionTest
//
//  Created by WCA on 3/15/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

import UIKit

@IBDesignable


open class RoundView: UIView {


}

public extension UILabel {
    
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            var opacity = min(newValue, 1)
            opacity = max(0, newValue)
            layer.shadowOpacity = opacity
        }
    }
    
    
    @IBInspectable var radius: Int {
        get{
            return Int(layer.shadowRadius)
        }
        set {
            self.layer.shadowRadius = CGFloat(newValue)
        }
    }
}
