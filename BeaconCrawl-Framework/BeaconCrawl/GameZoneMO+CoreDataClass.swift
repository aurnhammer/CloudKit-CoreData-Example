//
//  GameZoneMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 4/11/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

@objc(GameZoneMO)
public class GameZoneMO: NSManagedObject {
	
	@nonobjc public class func recordType() -> String {
		return "GameZone"
	}
	open override func awakeFromInsert() {
		super.awakeFromInsert()
		if let gameZone = entity.userInfo?["recordZone"] as? CKRecordZone {
			recordZoneID = gameZone.zoneID
		}
	}
}
