//
//  ShareMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 10/12/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

 //CKShare

@objc(ShareMO)
public class ShareMO: BaseMO {
	
	@nonobjc public class func recordType() -> String {
		return "Share"
	}
	
	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		if let record = record as? CKShare {
			var keys = keys
			
			if let name = self.name {
				record["cloudkit.title"] = name as NSString
			}
			
			if keys.contains("name"), let index = keys.index(of: "name") {
				keys.remove(at: index)
			}
			
			if let type = self.type {
				record["cloudkit.type"] = type as NSString
			}
			
			if keys.contains("type"), let index = keys.index(of: "type") {
				keys.remove(at: index)
			}
			
			if keys.contains("path"), let index = keys.index(of: "path") {
				keys.remove(at: index)
			}
			
			
			if let imageData = self.imageData {
				record["cloudkit.thumbnailImageData"] = imageData as NSData
			}
			
			if keys.contains("imageData"), let index = keys.index(of: "imageData") {
				keys.remove(at: index)
			}
			
			super.addAttributes(to: record, for: keys)
		}
	}
	
	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		if let string = record["cloudkit.type"] as? String {
			self["type"] = string as NSString
		}
		if keys!.contains("cloudkit.type"), let index = keys!.index(of: "cloudkit.type") {
			keys!.remove(at: index)
		}
		
		if let string = record["cloudkit.title"] as? String {
			self["name"] = string as NSString
		}
		
		if keys!.contains("cloudkit.title"), let index = keys!.index(of: "cloudkit.title") {
			keys!.remove(at: index)
		}
		
		if let data = record["cloudkit.thumbnailImageData"] as? Data {
			self["imageData"] = data as NSData
		}
		
		if keys!.contains("cloudkit.thumbnailImageData"), let index = keys!.index(of: "cloudkit.thumbnailImageData") {
			keys!.remove(at: index)
		}
		
		if let share = record as? CKShare {
			if let url = share.url {
				self.path = url.absoluteString
			}
			self.participants = Set<ShareParticipantMO>()
			let shareParticipants = share.participants
			for participantRecord: CKShareParticipant in shareParticipants {
				if let recordName = participantRecord.userIdentity.userRecordID?.recordName {
					let filter = NSPredicate(format: "participantID.recordName == %@", recordName)
					var shareParticipant: ShareParticipantMO? = nil
					
					
					if let participantObjects: [ShareParticipantMO] = DataManager.fetchLocalEntities(withType: "ShareParticipant",
																									 in: DataManager.viewContext,
																									 predicate: filter) as? [ShareParticipantMO],
						let participantObject = participantObjects.first {
						shareParticipant = participantObject
					}
					else {
						shareParticipant = DataManager.createManagedObject(forShareParticipant: participantRecord)
					}
					
					if let shareParticipant = shareParticipant {
						self.participants?.insert(shareParticipant)
					}
				}
			}
		}
		super.addAttributes(from: record, for: keys)
	}
}

