//
//  GameMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 4/4/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

private var myContext = 0

@objc(GameMO)
public class GameMO: BaseMO {

	@nonobjc public class func recordType() -> String {
        return District.game
    }
	
	open override func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		
		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		
        if let recordName = record["adventure"] as? String {
			adventure = recordName
        }

		if keys!.contains("adventure"), let index = keys!.index(of: "adventure") {
			keys!.remove(at: index)
		}
		
		super.addAttributes(from:record, for: keys)
    }
    
	open override func addAttributes(to record:CKRecord, for keys: [String]) {
		
		if let adventure = self.gameZone?.adventure {
            record["adventure"] = adventure.recordName as NSString?
            record["name"] = adventure.name as NSString?
            Log.message("Adventure changed: \(adventure)", enabled: false)
        }

		var keys = keys
		if keys.contains("adventure"), let index = keys.index(of: "adventure") {
			keys.remove(at: index)
		}
		
		if keys.contains("name"), let index = keys.index(of: "name") {
			keys.remove(at: index)
		}

		super.addAttributes(to:record, for: keys)
    }
 }
