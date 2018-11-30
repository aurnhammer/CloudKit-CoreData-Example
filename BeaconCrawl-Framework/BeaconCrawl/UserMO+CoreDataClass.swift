//
//  UserMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 3/13/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(UserMO)
public class UserMO: BaseMO {
	
	@nonobjc public class func recordType() -> String {
		return District.user
	}

	@objc open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
				
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		// Handle old key value. Now unused.
		if keys!.contains("clLocation"), let index = keys!.index(of: "clLocation") {
			keys!.remove(at: index)
		}
		
		if keys!.contains("location"), let index = keys!.index(of: "location") {
			keys!.remove(at: index)
		}
		
		super.addAttributes(from:record, for: keys)
    }
    
	@objc open override func addAttributes(to record:CKRecord, for keys: [String]) {
		var keys = keys
		
		if keys.contains("latitude") || keys.contains("longitude")  {
			record["location"] = self.location
			if let index = keys.index(of: "latitude") {
				keys.remove(at: index)
			}
			if let index = keys.index(of: "longitude") {
				keys.remove(at: index)
			}
		}
		
		super.addAttributes(to:record, for: keys)
    }
 }
