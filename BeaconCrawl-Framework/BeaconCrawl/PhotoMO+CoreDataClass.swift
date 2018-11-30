//
//  PhotoMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 2/21/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(PhotoMO)
public class PhotoMO: ImageMO {

	@nonobjc public class func recordType() -> String {
        return District.photo
    }

	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
        if let reference = record["game"] as? CKReference {
            let predicate = NSPredicate(format: "recordName == %@", reference.recordID.recordName)
			if let games:[GameMO] = DataManager.fetchLocalEntities(withType: District.game, predicate: predicate) as? [GameMO] {
                if let newGame = games.first {
                    game = newGame
                }
            }
        }
		
		if let recordName = record["userRecordName"] as? String {
			let predicate = NSPredicate(format: "recordName == %@", recordName)
			if let users:[UserMO] = DataManager.fetchLocalEntities(withType: District.user, predicate: predicate) as? [UserMO] {
				if let newUser = users.first {
					user = newUser
				}
			}
		}
		
		if keys!.contains("userRecordName"), let index = keys!.index(of: "userRecordName") {
			keys!.remove(at: index)
		}
		
		if keys!.contains("game"), let index = keys!.index(of: "game") {
			keys!.remove(at: index)
		}
		
		super.addAttributes(from:record, for: keys)
    }

	open override func addAttributes(to record:CKRecord, for keys: [String]) {

        // Save a photo as an asset
        if let game = self.game {
            let reference = CKReference(recordID: game.recordID, action: CKReferenceAction.none)
            record["game"] = reference
        }
		
		if let userRecordName = self.user?.recordName {
			record["userRecordName"] = userRecordName as NSString
		}
				
		var keys = keys
		if keys.contains("game"), let index = keys.index(of: "game") {
			keys.remove(at: index)
		}
		
		if keys.contains("user"), let index = keys.index(of: "user") {
			keys.remove(at: index)
		}

		super.addAttributes(to:record, for: keys)

    }
}
