//
//  Annotation.swift
//  District1
//
//  Created by WCA on 7/3/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import MapKit

open class Annotation: MKPointAnnotation {
		
	public var type: FilterView.Filter?
	public var recordID: CKRecordID?
    public var image: UIImage?
	public var radius: Double?

	public init(recordID: CKRecordID? = nil, coordinate: CLLocationCoordinate2D, image: UIImage? = nil, title: String? = nil, subtitle: String? = nil, type: FilterView.Filter? = .place, radius: Double? = nil) {
		super.init()
		self.recordID = recordID
		self.image = image
		self.title = title
		self.subtitle = subtitle
		self.type = type;
		self.radius = radius
		self.coordinate = coordinate
	}
}
