//
//  WebArchiveMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 4/23/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData


extension WebArchiveMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WebArchiveMO> {
        return NSFetchRequest<WebArchiveMO>(entityName: "WebArchive")
    }

    @NSManaged public var asset: Data?
    @NSManaged public var fileName: String?
    @NSManaged public var modifedDate: Date?
    @NSManaged public var url: String?
    @NSManaged public var isRemote: Bool
    @NSManaged public var adventures: Set<AdventureMO>?

}

// MARK: Generated accessors for adventures
extension WebArchiveMO {

    @objc(addAdventuresObject:)
    @NSManaged public func addToAdventures(_ value: AdventureMO)

    @objc(removeAdventuresObject:)
    @NSManaged public func removeFromAdventures(_ value: AdventureMO)

    @objc(addAdventures:)
    @NSManaged public func addToAdventures(_ values: NSSet)

    @objc(removeAdventures:)
    @NSManaged public func removeFromAdventures(_ values: NSSet)

}
