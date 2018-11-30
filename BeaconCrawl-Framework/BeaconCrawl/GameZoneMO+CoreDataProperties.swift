//
//  GameZoneMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 4/12/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//
//

import Foundation
import CoreData
import CloudKit

extension GameZoneMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameZoneMO> {
        return NSFetchRequest<GameZoneMO>(entityName: "GameZone")
    }

    @NSManaged public var recordZoneID: CKRecordZoneID?
    @NSManaged public var serverChangeToken: CKServerChangeToken?
    @NSManaged public var adventure: AdventureMO?
    @NSManaged public var game: GameMO?

}
