//
//  WebArchiveMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 4/4/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(WebArchiveMO)
public class WebArchiveMO: BaseMO {
	
	
	deinit {
		Log.message("Deinit WebarchiveMO")
	}
	
	@nonobjc public class func recordType() -> String {
		return District.webArchive
	}
	
	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		if let
			archiveAsset = record["asset"] as? CKAsset {
			do {
				self.asset = try Data(contentsOf: archiveAsset.fileURL)
				let fileURL = archiveAsset.fileURL
				self.fileName = fileURL.lastPathComponent
			}
			catch {
				Log.message("Error returning Archive in AdventureMO")
			}
		}
		
		
		if let references = record["adventures"] as? [CKReference] {
			let recordNames = references.map{$0.recordID.recordName}
			let predicate = NSPredicate(format: "recordName IN %@", recordNames)
			if let adventures:[AdventureMO] = DataManager.fetchLocalEntities(withType: "Adventure",
																			 in: DataManager.backgroundContext,
																			 predicate: predicate) as? [AdventureMO] {
				self.adventures = Set(adventures)
			}
		}
		
		if keys != nil {
			keys = Array(Set(keys!).subtracting( ["adventures", "asset", "fileName"]))
		}
		
		super.addAttributes(from:record, for: keys)
	}
	
	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		var keys = keys
		if keys.contains("fileName"), let index = keys.index(of: "fileName") {
			keys.remove(at: index)
		}
		if keys.contains("recordChangeTag"), let index = keys.index(of: "recordChangeTag") {
			keys.remove(at: index)
		}
		super.addAttributes(to:record, for: keys)
	}
}

