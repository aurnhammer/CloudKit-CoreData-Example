//
//  GameShareMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/15/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension GameShareMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameShareMO> {
        return NSFetchRequest<GameShareMO>(entityName: "GameShare")
    }

	@NSManaged public var adventureRecordName: String?
	@NSManaged public var state: String?
	@NSManaged public var game: GameMO?
	@NSManaged public var share: ShareMO?
	@NSManaged public var photos: Set<PhotoMO>?

}
