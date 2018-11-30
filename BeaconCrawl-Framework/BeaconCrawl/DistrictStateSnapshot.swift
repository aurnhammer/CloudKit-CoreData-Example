/*
 DistrictStateSnapshot.swift
 BeaconCrawl
 
 Created by WCA on 2/26/17.
 Copyright © 2017 aurnhammer.com. All rights reserved.
 
 Abstract:
 These types are used by the game's AI to capture and evaluate a snapshot of the game's state. `EntityDistance` encapsulates the distance between two entities. `AdventureStateSnapshot` stores an `EntitySnapshot` for every entity in the adventure. `EntitySnapshot` stores the distances from an entity to every other entity in the Adventure.
 
 */

import GameplayKit

struct DistrictStateSnapshot {
    
    /// A dictionary whose keys are entities, and whose values are entity snapshots for those entities.
    var adventureSnapshots: [AdventureMO: AdventureStateSnapshot] = [:]
    

}
