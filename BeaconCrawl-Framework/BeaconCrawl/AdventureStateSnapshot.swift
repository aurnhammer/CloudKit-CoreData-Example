/*
AdventureStateSnapshot.swift
BeaconCrawl

Created by WCA on 2/26/17.
Copyright © 2017 aurnhammer.com. All rights reserved.

Abstract:
These types are used by the game's AI to capture and evaluate a snapshot of the game's state. `EntityDistance` encapsulates the distance between two entities. `AdventureStateSnapshot` stores an `EntitySnapshot` for every entity in the adventure. `EntitySnapshot` stores the distances from an entity to every other entity in the Adventure.

*/


import GameplayKit

/// Encapsulates two entities and their distance apart.
struct EntityDistance {
	let source: GKEntity
	let target: GKEntity
	let distance: Float
}

/**
Stores a snapshot of the state of a adventure and all of its entities
(`PlayerEntities`, `FriendEntities` and `EnemyEnities`s) at a certain point in time.
*/
struct AdventureStateSnapshot {
	// MARK: Properties
	
	/// A dictionary whose keys are entities, and whose values are entity snapshots for those entities.
	var entitySnapshots: [GKEntity: EntitySnapshot] = [:]
	var adventure: AdventureMO!
	// MARK: Initialization
	
	/// Initializes a new `AdventureStateSnapshot` representing all of the entities in an `Adventure`.
	init(withAdventure adventure: AdventureMO) {
		self.adventure = adventure
		/// Returns the `GKAgent3D` for a `PlayerEntity` or `FriendEntity`.
		func objectForEntity(entity: GKEntity) -> BaseMO? {
			return nil
		}
		
		// A dictionary that will contain a temporary array of `EntityDistance` instances for each entity.
		var _: [GKEntity: [EntityDistance]] = [:]
	}
}

extension AdventureStateSnapshot {
	
	func stateAsDictionary () -> [String: String] {
		let dictionary: [String: String]  = ["username": "",
											 "totalScore": "",
											 "crawlScore": "",
											 "venueName": "",
											 "venueId": "",
											 "currentVenueName": "",
											 "crawlName": "",
											 "crawlId": "",
											 "currentCrawlName": "",
											 "currenCrawlId": "",
											 "userResult": ""]
		return dictionary
	}
}

class EntitySnapshot {
	
	/// The factor used to normalize distances between characters for 'fuzzy' logic.
	let proximityFactor: Float
	
	// MARK: Properties
	/// Distance to the `Place` if it is targetable.
	let nearestPlaceTarget: (target: PlaceEntity, distance: Float)?
	
	/// A sorted array of distances from this entity to every other entity in the level.
	let entityDistances: [EntityDistance]
	
	init(proximityFactor: Float, entityDistances: [EntityDistance]) {
		self.proximityFactor = proximityFactor
		// Sort the `entityDistances` array by distance (nearest first), and store the sorted version.
		self.entityDistances = entityDistances.sorted {
			return $0.distance < $1.distance
		}
		
		var nearestPlaceTarget: (target: PlaceEntity, distance: Float)?
		
		for entityDistance in self.entityDistances {
			if let target = entityDistance.target as? PlaceEntity, nearestPlaceTarget == nil && target.isTargetable {
				nearestPlaceTarget = (target: target, distance: entityDistance.distance)
			}
			else if entityDistance.target is PlaceEntity { //nearestGoodTaskBotTarget == nil && target.isGood {
				//nearestGoodTaskBotTarget = (target: target, distance: entityDistance.distance)
			}
			
			// Stop iterating over the array once we have found both the `PlayerBot` and the nearest good `TaskBot`.
			if nearestPlaceTarget != nil {
				break
			}
			
		}
		self.nearestPlaceTarget = nearestPlaceTarget
	}
}


