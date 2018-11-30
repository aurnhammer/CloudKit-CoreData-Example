//
//  GameSessionMO+CoreDataProperties.swift
//  BeaconCrawl
//
//  Created by WCA on 3/10/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import GameKit


extension GameSessionMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameSessionMO> {
        return NSFetchRequest<GameSessionMO>(entityName: "GameSession");
    }

    @NSManaged public var gkGameSession: GKGameSession!
    @NSManaged public var identifier: String?
    @NSManaged public var lastModifiedPlayer: GKCloudPlayer?
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var maxNumberOfConnectedPlayers: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var urlString: String?
    @NSManaged public var gameData: Data?
    @NSManaged public var players: Set<GKCloudPlayer>?
    @NSManaged public var adventure: AdventureMO?

}
