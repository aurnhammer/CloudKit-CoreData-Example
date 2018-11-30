//
//  GameSessionMO+CoreDataClass.swift
//  BeaconCrawl
//
//  Created by WCA on 3/10/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import GameKit

@objc(GameSessionMO)
public class GameSessionMO: NSManagedObject {
    
    open override func awakeFromInsert() {
        super.awakeFromInsert()
        let session = entity.userInfo?["gameSession"] as! GKGameSession
        gkGameSession = session
        addAttributes(fromGameSession: session)
    }

    open func addAttributes(fromGameSession session: GKGameSession) {
        identifier = session.identifier
        lastModifiedPlayer = session.lastModifiedPlayer
        lastModifiedDate = session.lastModifiedDate
        maxNumberOfConnectedPlayers = NSNumber.init(value: session.maxNumberOfConnectedPlayers)
        title = session.title
        players = Set(session.players)
    }
    
    open func addAttributes(toGameSession session:GKGameSession) {
    }

}
