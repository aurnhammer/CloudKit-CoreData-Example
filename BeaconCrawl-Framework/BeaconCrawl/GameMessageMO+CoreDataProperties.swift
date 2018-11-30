//
//  GameMessageMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/24/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension GameMessageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameMessageMO> {
        return NSFetchRequest<GameMessageMO>(entityName: "GameMessage")
    }

	@NSManaged public var string: String?
	@NSManaged public var recipients: Set<UserMO>?
	@NSManaged public var game: GameMO?
	@NSManaged public var sender: UserMO?
	
}

// MARK: Generated accessors for recipients
extension GameMessageMO {

    @objc(addRecipientsObject:)
    @NSManaged public func addToRecipients(_ value: UserMO)

    @objc(removeRecipientsObject:)
    @NSManaged public func removeFromRecipients(_ value: UserMO)

    @objc(addRecipients:)
    @NSManaged public func addToRecipients(_ values: NSSet)

    @objc(removeRecipients:)
    @NSManaged public func removeRecipients(_ values: NSSet)

}
