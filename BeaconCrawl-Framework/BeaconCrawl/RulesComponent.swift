/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` and associated delegate that manage and respond to a `GKRuleSystem` for an entity.
*/

import GameplayKit

protocol RulesComponentDelegate: class {
    // Called whenever the rules component finishes evaluating its rules.
    func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem)
}

class RulesComponent: GKComponent {

    // MARK: Properties
    weak var delegate: RulesComponentDelegate?
    
    var placeStateSnapshot: PlaceStateSnapshot?
	var beaconStateSnapshot: BeaconStateSnapshot?
	var playerStateSnapshot: PlayerStateSnapshot?

    /// The amount of time that has passed since the `Player Entity` last evaluated its rules.
    private var timeSinceRulesUpdate: TimeInterval = 0.0
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: GKComponent Life Cycle
    
    override func update(deltaTime seconds: TimeInterval) {
        timeSinceRulesUpdate = 0.0
        timeSinceRulesUpdate += seconds
        if let player = entity as? PlayerEntity {
            // Create a snapshot of the Player's place if one does not already exist for this update cycle.
            if placeStateSnapshot == nil {
                placeStateSnapshot = PlaceStateSnapshot(player: player)
            }
            else {
                let newPlaceStateSnapshot = PlaceStateSnapshot(player: player)
                if placeStateSnapshot! != newPlaceStateSnapshot {
                    placeStateSnapshot = newPlaceStateSnapshot
                    if let snapShot = placeStateSnapshot?.snapShot {
						if snapShot != "" {
							Log.message("Place Snap Shot \(snapShot)", enabled: false)
							NotificationCenter.default.post(name: .PlaceUpdatedNotification, object: snapShot)
						}
					}
                }
            }
			if playerStateSnapshot == nil {
				playerStateSnapshot = PlayerStateSnapshot(player: player)
			}
			else {
				let newPlayerStateSnapshot = PlayerStateSnapshot(player: player)
				if playerStateSnapshot! != newPlayerStateSnapshot {
					playerStateSnapshot = newPlayerStateSnapshot
					if let snapShot = playerStateSnapshot?.snapShot {
						if snapShot != "" {
							Log.message("Player Snap Shot \(snapShot)", enabled: false)
							NotificationCenter.default.post(name: .PlayerUpdatedNotification, object: snapShot)
						}
					}
				}
			}

            /*
            if beaconStateSnapshot == nil {
                beaconStateSnapshot = BeaconStateSnapshot(player: player)
            }
            else {
                let newBeaconStateSnapshot = BeaconStateSnapshot(player: player)
                if beaconStateSnapshot! != newBeaconStateSnapshot {
                    beaconStateSnapshot = newBeaconStateSnapshot
                }
            }
            if let snapShot = beaconStateSnapshot?.snapShot {
                NotificationCenter.default.post(name: .BeaconUpdatedNotification, object: snapShot)
            }*/
        }
    }
}
