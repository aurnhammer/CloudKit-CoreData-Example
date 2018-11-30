//
//  MarkerAnnotationView.swift
//  District1
//
//  Created by WCA on 7/3/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import MapKit

@available(iOS 11.0, *)
open class MarkerAnnotationView: MKMarkerAnnotationView {
	
	public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
		super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func setup() {
		self.canShowCallout = true
		let disclosureButton : UIButton = UIButton(type:UIButtonType.detailDisclosure)
		self.rightCalloutAccessoryView = disclosureButton
//		centerOffset = CGPoint(x: 0, y: 0) // Offset center point to animate better with marker annotations
	}
	
	override open var annotation: MKAnnotation? {
		willSet {
			if let annotation = newValue as? Annotation {
				clusteringIdentifier = "place"
				if let type = annotation.type {
					switch type {
					case .place:
						markerTintColor = UIColor(named: "green")
						glyphImage = UIImage(named: "Places")
						displayPriority = .defaultLow
					case .game:
						markerTintColor = UIColor(named: "blue")
						glyphImage = UIImage(named: "Games")
						displayPriority = .defaultHigh
					case .event:
						markerTintColor = UIColor(named: "orange")
						glyphImage = UIImage(named: "Events")
						displayPriority = .defaultHigh
					case .tour:
						markerTintColor = UIColor(named: "purple")
						glyphImage = UIImage(named: "Tours")
						displayPriority = .defaultHigh
					case .none:
						markerTintColor = UIColor(named: "gray")
						displayPriority = .defaultLow
					}
				}
				if let image = annotation.image {
					let imageView = UIImageView(image: Image.scaled(image: image, toWidth: 10, andHeight: 10))
					self.leftCalloutAccessoryView = imageView
				}
			}
		}
	}
}
