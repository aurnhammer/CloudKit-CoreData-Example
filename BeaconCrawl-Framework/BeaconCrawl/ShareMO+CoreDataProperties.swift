//
//  ShareMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/16/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension ShareMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShareMO> {
        return NSFetchRequest<ShareMO>(entityName: "Share")
    }

	@NSManaged public var imageData: Data?
	@NSManaged public var type: String?
	@NSManaged public var gameShare: GameShareMO?
	@NSManaged public var participants: Set<ShareParticipantMO>?
    @NSManaged public var path: String?
}

// MARK: Generated accessors for participants
extension ShareMO {

    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: ShareParticipantMO)

    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: ShareParticipantMO)

    @objc(addParticipants:)
    @NSManaged public func addToParticipants(_ values: NSSet)

    @objc(removeParticipants:)
    @NSManaged public func removeFromParticipants(_ values: NSSet)

}
