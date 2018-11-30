//
//  GameMessageMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 3/15/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

@objc(GameMessageMO)
public class GameMessageMO: BaseMO {

	@nonobjc public class func recordType() -> String {
		return "GameMessage"
	}
	
	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {

		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		if let recordName = record["game"] as? String {
			let predicate = NSPredicate(format: "recordName == %@", recordName)
			if let games:[GameMO] = DataManager.fetchLocalEntities(withType: District.game,
																   in: DataManager.viewContext,
																   predicate: predicate) as? [GameMO] {
				if let firstGame = games.first {
					game = firstGame
				}
			}
		}
		
		if let senderReference = record["sender"] as? CKReference {
			let predicate = NSPredicate(format: "recordName == %@", senderReference.recordID.recordName)
			if let users:[UserMO] = DataManager.fetchLocalEntities(withType: District.user,
																   in: DataManager.viewContext,
																   predicate: predicate) as? [UserMO], let firstUser = users.first {
				sender = firstUser
			}
		}
		
		if let recipientsReferences = record["recipients"] as? [CKReference] {
			let recordNames = recipientsReferences.map({$0.recordID.recordName})
			let predicate = NSPredicate(format: "recordName IN %@", recordNames)
			if let users:[UserMO] = DataManager.fetchLocalEntities(withType: District.user,
																   in: DataManager.viewContext,
																   predicate: predicate) as? [UserMO] {
				recipients = Set(users)
			}
		}

		if keys!.contains("game"), let index = keys!.index(of: "game") {
			keys!.remove(at: index)
		}
		
		if keys!.contains("sender"), let index = keys!.index(of: "sender") {
			keys!.remove(at: index)
		}

		if keys!.contains("recipients"), let index = keys!.index(of: "recipients") {
			keys!.remove(at: index)
		}

		super.addAttributes(from:record, for: keys)
	}

	open override func addAttributes(to record:CKRecord, for keys: [String]) {
				
		if let game = self.game {
			record["game"] = game.recordName as NSString
			record["name"] = game.name as NSString?
		}

		
		if let sender = self.sender {
			let reference = CKReference(recordID: sender.recordID, action: CKReferenceAction.none)
			record["sender"] = reference
		}

		if let recipients = self.recipients, !recipients.isEmpty {
			record["recipients"] = recipients.map{CKReference(recordID: $0.recordID, action: CKReferenceAction.none)} as NSArray
		}

		var keys = keys
		if keys.contains("game"), let index = keys.index(of: "game") {
			keys.remove(at: index)
		}
		
		if keys.contains("name"), let index = keys.index(of: "name") {
			keys.remove(at: index)
		}

		
		if keys.contains("sender"), let index = keys.index(of: "sender") {
			keys.remove(at: index)
		}

		if keys.contains("recipients"), let index = keys.index(of: "recipients") {
			keys.remove(at: index)
		}

		super.addAttributes(to:record, for: keys)
	}
}
