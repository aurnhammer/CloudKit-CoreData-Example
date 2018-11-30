//
//  AdventureDescriptionMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 12/23/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(AdventureDescriptionMO)
public class AdventureDescriptionMO: ImageMO {
	
	@nonobjc public class func recordType() -> String {
		return District.adventureDescription
	}

	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		if let reference = record["reference"] as? CKReference {
			Log.message("Reference: \(reference)")
			let predicate = NSPredicate(format: "recordName = %@", reference.recordID.recordName)
			if let adventures:[AdventureMO] = DataManager.fetchLocalEntities(withType: "Adventure",
																			 in: DataManager.viewContext,
																			 predicate: predicate) as? [AdventureMO], let adventure = adventures.first {
				self.adventure = adventure
			}
		}

		if keys!.contains("reference"), let index = keys!.index(of: "reference") {
			keys!.remove(at: index)
		}

		super.addAttributes(from:record, for: keys)

    }

	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		
        if let adventure = self.adventure {
            let reference = CKReference(recordID: adventure.recordID, action: CKReferenceAction.none)
            record["reference"] = reference
        }
		
		var keys = keys
		if keys.contains("reference"), let index = keys.index(of: "reference") {
			keys.remove(at: index)
		}

		super.addAttributes(to:record, for: keys)

    }
 }
