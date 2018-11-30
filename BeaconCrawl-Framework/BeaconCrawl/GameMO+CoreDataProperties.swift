//
//  GameMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 4/12/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension GameMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameMO> {
        return NSFetchRequest<GameMO>(entityName: "Game")
    }

	@NSManaged public var beaconState: String?
	@NSManaged public var gameState: String?
	@NSManaged public var placeState: String?
	@NSManaged public var isFavorite: NSNumber?
	@NSManaged public var gameShare: GameShareMO?
	@NSManaged public var path: String?
	@NSManaged public var photos: Set<PhotoMO>?
	@NSManaged public var message: GameMessageMO?
	@NSManaged public var gameZone: GameZoneMO?
	@NSManaged public var adventure: String?

}

// MARK: Generated accessors for photos
extension GameMO {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: PhotoMO)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: PhotoMO)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}
