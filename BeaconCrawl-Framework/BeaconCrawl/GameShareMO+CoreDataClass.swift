//
//  GameShareMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 10/9/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

@objc(GameShareMO)
public class GameShareMO: BaseMO {
	
	@nonobjc public class func recordType() -> String {
		return "GameShare"
	}

	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		
		var keys = keys
		
		if keys.contains("game"), let index = keys.index(of: "game") {
			keys.remove(at: index)
		}
				
		if keys.contains("share"), let index = keys.index(of: "share") {
			keys.remove(at: index)
		}

		super.addAttributes(to: record, for: keys)
	}

	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}

		if let reference = record.share  {
			let predicate = NSPredicate(format: "recordName = %@", reference.recordID.recordName)
			if let shares:[ShareMO] = DataManager.fetchLocalEntities(withType: "Share", predicate: predicate) as? [ShareMO], let share = shares.first {
				self.share = share
			}
		}
		
		super.addAttributes(from: record, for: keys)
	}

}
