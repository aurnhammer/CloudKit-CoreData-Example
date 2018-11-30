//
//  PlaceMO+CoreDataClass.swift
//  Notifications
//
//  Created by WCA on 8/25/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@objc(PlaceMO)
open class PlaceMO: BaseMO {
	
	
	@nonobjc public class func recordType() -> String {
		return District.place
	}
	
	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		
		// Don't copy imageData upto Database because it is self generating
		var keys = keys
		
		if keys.contains("imageData"), let index = keys.index(of: "imageData") {
			keys.remove(at: index)
		}
		
		super.addAttributes(to: record, for: keys)
	}
}
