//
//  AnnotationView.swift
//  BeaconCrawl
//
//  Created by WCA on 6/17/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//

import UIKit
import MapKit

open class AnnotationView: MKPinAnnotationView {
	
	weak var mapView : MKMapView?
	var isRadiusUpdated : Bool! = false
	var radiusOverlay : MKCircle!
	
	public init(annotation: Annotation?, mapView: MKMapView?, reuseIdentifier: String) {
		super.init(annotation:annotation, reuseIdentifier:reuseIdentifier)
		self.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
		self.canShowCallout	= true
		self.isMultipleTouchEnabled = false
		self.animatesDrop = true
		self.isDraggable = true
		self.tintColor = UIColor.init(red: 100.0/255, green: 169.0/255.0, blue: 25.0/255.0, alpha: 1.0)
		self.mapView = mapView
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// Update the circular overlay if the radius has changed.
	open func updateRadiusOverlay() {
		self.isRadiusUpdated = true
		self.removeRadiusOverlay()
		self.canShowCallout = false
		if let
			annotation: Annotation = self.annotation as? Annotation {
			self.radiusOverlay = MKCircle(center: annotation.coordinate, radius: 50)
			self.mapView?.add(self.radiusOverlay)
		}
		self.canShowCallout = true
	}
	
	func removeRadiusOverlay() {
		if let radiusOverlay = self.radiusOverlay {
			// Find the overlay for this annotation view and remove it if it has the same coordinates.
			self.mapView?.remove(radiusOverlay)
			self.isRadiusUpdated = false
		}
	}
}
