//
//  AdventureMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 4/12/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension AdventureMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AdventureMO> {
        return NSFetchRequest<AdventureMO>(entityName: "Adventure")
    }

	@NSManaged public var accuracy: NSNumber?
	@NSManaged public var city: String?
	@NSManaged public var date: NSDate?
	@NSManaged public var descriptiveText: String?
	@NSManaged public var duration: NSNumber?
	@NSManaged public var imageData: Data?
	@NSManaged public var state: String?
	@NSManaged public var street: String?
	@NSManaged public var tags: String?
	@NSManaged public var zip: String?
	@NSManaged public var descriptions: Set<AdventureDescriptionMO>?
	@NSManaged public var webArchive: WebArchiveMO?
	@NSManaged public var isEnabled: NSNumber?
	@NSManaged public var isVisible: NSNumber?
	@NSManaged public var gameZone: GameZoneMO?

}

// MARK: Generated accessors for descriptions
extension AdventureMO {

    @objc(addDescriptionsObject:)
    @NSManaged public func addToDescriptions(_ value: AdventureDescriptionMO)

    @objc(removeDescriptionsObject:)
    @NSManaged public func removeFromDescriptions(_ value: AdventureDescriptionMO)

    @objc(addDescriptions:)
    @NSManaged public func addToDescriptions(_ values: NSSet)

    @objc(removeDescriptions:)
    @NSManaged public func removeFromDescriptions(_ values: NSSet)

}
