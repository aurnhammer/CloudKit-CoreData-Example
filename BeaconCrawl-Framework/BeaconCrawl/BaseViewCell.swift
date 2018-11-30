//
//  BaseViewCell..swift
//  Notifications
//
//  Created by WCA on 8/7/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit

@IBDesignable

open class BaseViewCell: UICollectionViewCell {
    
    @IBOutlet public weak var progressView: UIProgressView?
    @IBOutlet public weak var imageView: UIImageView?
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var detailLabel: UILabel?
	@IBOutlet public weak var loadingView: UIView?
	@IBOutlet public weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet public weak var accessoryView: UIView?
    @IBOutlet public weak var favoriteIcon: UIImageView?
    
    @IBInspectable var selectedBackgroundColor: UIColor? = UIColor.white

    @IBInspectable public var isHighlightable: Bool = true {
        didSet {
            if isHighlightable == true {
                selectedBackgroundView?.backgroundColor = selectedBackgroundColor
            }
            else {
                selectedBackgroundView?.backgroundColor = nil
            }
        }
    }

    public var primaryTag: String? {
        didSet {
            if oldValue != nil {
                self.progressView?.progressTintColor = Tagged.colorForTag(string: primaryTag)
                imageView?.image = Tagged.imageForTag(string: primaryTag)
				imageView?.tintColor = Tagged.colorForTag(string: primaryTag)
			}
        }
    }

	public var isLoading: Bool? {
		didSet {
			if let loadingView = self.loadingView, let isLoading = isLoading {
				if isLoading {
					loadingView.isHidden = false
					activityIndicator?.startAnimating()
				}
				else {
					loadingView.isHidden = true
					activityIndicator?.stopAnimating()
				}
			}
		}
	}

    public var isFavorite: Bool? {
        didSet {
            if let favoriteIcon = self.favoriteIcon, let isFavorite = isFavorite {
                if isFavorite {
                    favoriteIcon.isHidden = false
                }
                else {
                    favoriteIcon.isHidden = true
                }
            }
        }
    }

    public var backgroundImage: UIImage? {
        get {
            guard let backgroundView: UIImageView = self.backgroundView as! UIImageView? else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n", enabled: false)
                return nil
            }
            return backgroundView.image
        }
        set {
            guard let backgroundView: UIImageView = self.backgroundView as! UIImageView? else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n", enabled: false)
                return
            }
//            backgroundView.contentMode = UIViewContentMode.scaleAspectFill
            backgroundView.image = newValue
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            if self.accessoryView is UIButton {
                let accessoryView: UIButton = self.accessoryView as! UIButton
                accessoryView.isSelected = isSelected
            }
        }
    }

    open override func awakeFromNib() {
        selectedBackgroundView = UIView()
        //self.isSelected = true
        if isHighlightable == true {
            selectedBackgroundView?.backgroundColor = selectedBackgroundColor
        }
        else {
            selectedBackgroundView?.backgroundColor = nil
        }
    }
	
	override open func prepareForReuse() {
		super.prepareForReuse()
		if let activityIndicator = self.activityIndicator {
			activityIndicator.startAnimating()
		}
	}

    public func set(title: String? = nil, detail: String? = nil, backgroundImage: UIImage? = nil, primaryTag: String? = nil, favorite: Bool? = false) {
        self.backgroundImage = backgroundImage 
        self.titleLabel?.text = title
        self.detailLabel?.text = detail
        self.primaryTag = primaryTag
        self.isFavorite = favorite
    }
}


public struct Tagged {
    public static func colorForTag(string: String?) -> UIColor? {
        switch string {
        case .some("Game"):
			if #available(iOS 11.0, *) {
				return UIColor(named:"blue")
			} else {
				return UIColor(red: 63.0/255.0, green: 140.0/255.0, blue: 230.0/255.0, alpha: 1.0)
			}
        case .some("Tour"):
			if #available(iOS 11.0, *) {
				return UIColor(named:"purple")
			} else {
				return UIColor(red: 204.0/255.0, green: 102.0/255.0, blue: 255.0/255.0, alpha: 1.0)
			}
        case .some("Place"):
			if #available(iOS 11.0, *) {
				return UIColor(named:"green")
			} else {
				return UIColor(red: 100.0/255, green: 169.0/255.0, blue: 25.0/255.0, alpha: 1.0)
			}
         case .some("Event"):
			if #available(iOS 11.0, *) {
				return UIColor(named:"green")
			} else {
				return UIColor.init(red: 217.0/255, green: 136.0/255.0, blue: 0.0/255.0, alpha: 1.0)
			}
        default:
            return nil
        }
    }
    
    public static func imageForTag(string: String?) -> UIImage? {
        switch string {
        case .some("Game"):
            return UIImage(named: "Games")
        case .some("Tour"):
            return UIImage(named: "Tours")
        case .some("Place"):
            return UIImage(named: "Places")
        case .some("Event"):
            return UIImage(named: "Events")
        default:
            return nil
        }
    }
}
