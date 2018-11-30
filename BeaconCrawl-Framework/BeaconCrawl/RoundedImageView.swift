//
//  RoundedImageView.swift
//  BeaconCrawl
//
//  Created by WCA on 4/21/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit

@IBDesignable

open class RoundedImageView: UIImageView {

    open override func prepareForInterfaceBuilder() {
        subviews.forEach {
            $0.prepareForInterfaceBuilder()
        }
    }

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var round: Bool = false {
        didSet {
            if round == true {
                layer.cornerRadius = self.bounds.size.width * 0.5
            }
            else {
                layer.cornerRadius = cornerRadius
            }
        }
    }
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		if round == true {
			layer.cornerRadius = self.bounds.size.width * 0.5
		}
		else {
			layer.cornerRadius = cornerRadius
		}
	}
}

open class RoundedButton: UIButton {

    open override func prepareForInterfaceBuilder() {
        subviews.forEach {
            $0.prepareForInterfaceBuilder()
        }
    }

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var round: Bool = false {
        didSet {
            if round == true {
                layer.cornerRadius = self.bounds.size.width * 0.5
            }
            else {
                layer.cornerRadius = cornerRadius
            }
        }
    }
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		if round == true {
			layer.cornerRadius = self.bounds.size.width * 0.5
		}
		else {
			layer.cornerRadius = cornerRadius
		}
	}
}


