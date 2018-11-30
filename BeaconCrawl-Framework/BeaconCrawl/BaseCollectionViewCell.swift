//
//  BaseCollectionViewCell.swift
//  District-1 Admin
//
//  Created by WCA on 7/26/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import MapKit

open class BaseCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet open weak var titleLabel: UILabel?
	@IBOutlet open weak var detailLabel: UILabel?
	@IBOutlet open weak var accuracyLabel: UILabel?
	@IBOutlet open weak var imageView: UIImageView?

	open func set(_ title: String? = nil, detail: String? = nil, accuracy: String? = nil) {
		self.titleLabel?.text = title
		self.detailLabel?.text = detail
		self.accuracyLabel?.text = accuracy
	}
}
