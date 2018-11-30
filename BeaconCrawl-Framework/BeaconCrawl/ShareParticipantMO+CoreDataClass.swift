//
//  ShareParticipantMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 11/17/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

@objc(ShareParticipantMO)
public class ShareParticipantMO: NSManagedObject {
	
	@nonobjc public class func recordType() -> String {
		return "ShareParticipant"
	}
	
	open override func awakeFromInsert() {
		super.awakeFromInsert()
		if let shareParticipant = entity.userInfo?["shareParticipant"] as? CKShareParticipant {
			self.type = NSNumber(value:shareParticipant.type.hashValue)
			self.acceptanceStatus = NSNumber(value:shareParticipant.acceptanceStatus.rawValue)
			self.permission = NSNumber(value:shareParticipant.permission.rawValue)
			let userIdentity = shareParticipant.userIdentity
			self.participantID = userIdentity.userRecordID
			if let givenName = userIdentity.nameComponents?.givenName,
			let familyName = userIdentity.nameComponents?.familyName {
				self.name = givenName + " " + familyName
				Log.message("Name \(givenName)" + " " + familyName)
			}
		}
	}
}
