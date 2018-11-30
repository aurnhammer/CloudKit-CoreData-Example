//
//  BeaconMO+CoreDataClass.swift
//  Notifications
//
//  Created by WCA on 8/25/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import MapKit

@objc(BeaconMO)
open class BeaconMO: BaseMO {
	
	@nonobjc public class func recordType() -> String {
		return District.beacon
	}
	
	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		var keys = keys
		if keys.contains("imageData"), let index = keys.index(of: "imageData") {
			keys.remove(at: index)
		}
		super.addAttributes(to: record, for: keys)
	}
}
