//
//  PromotionalPageTableViewCell.swift
//  Notifications
//
//  Created by Bill A on 8/20/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import BeaconCrawl

class PromotionalPageTableViewCell: UITableViewCell {

    @IBOutlet var title: UILabel?
    @IBOutlet var detail: UILabel?
    @IBOutlet var roundImageView: UIImageView?
    
    func configure(for image: ImageMO) {
        if let data = image.imageData {
            self.roundImageView?.image = UIImage(data: data)
        }
        title?.text = image.name
    }
}
