//
//  FeedDetailViewController.swift
//  BeaconCrawl
//
//  Created by WCA on 5/15/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//

import UIKit

public class FeedDetailViewController: UIViewController {

	var photo: PhotoMO!
	@IBOutlet weak var imageView: UIImageView!
	
	override public func viewDidLoad() {
        super.viewDidLoad()
		setup()
    }

	override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func setup() {
		setupImageView()
	}
	
	func setupImageView() {
		if let imageData = photo.imageData {
			imageView.image = UIImage(data:imageData)
		}
	}

	@IBAction func shareButtonPressed(_ button: UIBarButtonItem) {
		
		if let photo = self.photo {
			var activityItems = [Any]()
			if let data = photo.imageData, let image = UIImage(data: data) {
				activityItems.append(image)
			}
			let viewController = UIActivityViewController(activityItems:activityItems, applicationActivities: [])
			if let popoverPresentationController = viewController.popoverPresentationController {
				popoverPresentationController.barButtonItem = button
			}
			self.present(viewController, animated: true)
		}
	}

}
