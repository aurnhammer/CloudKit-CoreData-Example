//
//  PlayerEntity.swift
//  Notifications
//
//  Created by WCA on 9/25/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import GameplayKit
import CoreLocation

@objc public protocol PlayerEntityDelegate: class {
     func playerEntity(_ entity: PlayerEntity, didChangeState state: PlayerState)
}

@objc open class PlayerEntity: GKEntity, RulesComponentDelegate {

    var stateMachine: GKStateMachine!
    var user: UserMO!
    public var currentBeacon: CLBeacon?
	public var sortedBeacons: [(NSNumber, [CLBeacon])]?

	private var timeSinceBeaconUpdate: TimeInterval = 0.0

    public weak var delegate: PlayerEntityDelegate?
    var isTargetable: Bool = false

    public convenience init(with player: UserMO, component: GKComponent) {
        self.init()
        self.user = player
        addComponent(component)
        // Create and add a rules component to encapsulate all of the rules that can affect a `Player Entity`'s behavior.
        let rulesComponent = RulesComponent()
        addComponent(rulesComponent)
        rulesComponent.delegate = self
    }

    override init() {
        super.init()
        setUpStates()
    }
    
    deinit {
        Log.message("Player Entity Deinit")
    }
	
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpStates() {
        // Creates and adds states to the Player Entity’s state machine.
        stateMachine = GKStateMachine(states: [InsideRegionState(withEntity: self), OutsideRegionState(withEntity: self), InsidePlaceState(withEntity: self), InsideBeaconState(withEntity: self)])
        stateMachine.enter(OutsideRegionState.self)
    }
    
    func updateState(_ stateClass: AnyClass) {
        stateMachine.enter(stateClass)
    }
	
    override open func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        self.stateMachine.update(deltaTime: seconds)

        guard let rangingComponent = self.component(ofType: RangingComponent.self) else  {
			Log.message("There is no ranging component")
            return
        }
        self.sortedBeacons = rangingComponent.sortedBeacons
		if let (_, beacons) = sortedBeacons?.first, let beacon = beacons.first {
			self.currentBeacon = beacon
        }
		else {
			currentBeacon = nil
		}
		delegate?.playerEntity(self, didChangeState: stateMachine.currentState as! PlayerState)
		NotificationCenter.default.post(name: .BeaconsUpdatedNotification, object: sortedBeacons)
    }
    
    // MARK: RulesComponentDelegate
    func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem) {
        
    }
}

