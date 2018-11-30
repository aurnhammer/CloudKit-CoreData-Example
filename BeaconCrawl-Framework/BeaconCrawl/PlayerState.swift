//
//  PlayerState.swift
//  Notifications
//
//  Created by WCA on 6/27/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import GameplayKit
import CoreLocation
import CloudKit
import CoreData

open class PlayerState: GKState {
    
    weak var playerEntity: PlayerEntity!
    
    convenience init(withEntity entity:PlayerEntity) {
        self.init()
        self.playerEntity = entity
    }
}

public class OutsideRegionState: PlayerState {
    
    private var nextStateRegion: CLBeaconRegion?
    
    override public func didEnter(from previousState: GKState?) {
        guard let regioningComponent: RegioningComponent = playerEntity.component(ofType: RegioningComponent.self) else {return}
        if let region = regioningComponent.beaconRegion {
            Log.message("State Outside Region \(region.identifier)")
        }
        playerEntity.removeComponent(ofType: RangingComponent.self)
    }
    
    override public func willExit(to nextState: GKState) {
        if let nextState = nextState as? InsideRegionState {
            nextState.region = self.nextStateRegion
        }
    }

    override public func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is InsideRegionState.Type:
            return true
        default:
            return false
        }
    }
}

public class InsideRegionState: PlayerState {
    
    var region: CLBeaconRegion!
    private var nextStatePlace: PlaceMO?
    
     override public func didEnter(from previousState: GKState?) {
        guard let regioningComponent: RegioningComponent = playerEntity.component(ofType: RegioningComponent.self) else {return}
        guard let region = regioningComponent.beaconRegion else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
            return
        }
        Log.message("State Inside Region \(region.identifier)")

        guard let previousState = previousState else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
            return
        }
        if previousState.isKind(of: OutsideRegionState.self) {
            let rangingComponent = RangingComponent(with: region)
            playerEntity.addComponent(rangingComponent)
        }
    }
    
    override public func willExit(to nextState: GKState) {
        if let nextState = nextState as? InsidePlaceState {
            nextState.place = self.nextStatePlace
        }
    }
        
    override public func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is OutsideRegionState.Type, is InsidePlaceState.Type:
            return true
        default:
            return false
        }
    }
    
    override public func update(deltaTime seconds: TimeInterval) {
        guard let currentBeacon = playerEntity.currentBeacon else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n", enabled: false)
            return
        }
        let fetchPlaceOperation = FetchPlaceOperation(major: currentBeacon.major)
        fetchPlaceOperation.start()
        fetchPlaceOperation.fetchPlaceCompletionBlock = { (place) in
            if let place = place {
                Log.message("Outside Place \(place.name!) accuracy \(currentBeacon.accuracy)", enabled: true)
                if let accuracy = place.accuracy {
                    if currentBeacon.accuracy <= accuracy.doubleValue {
                        self.nextStatePlace = place
                        self.playerEntity.updateState(InsidePlaceState.self)
                    }
                }
            }
        }
    }
}

public class InsidePlaceState: PlayerState {
    
    var place: PlaceMO?
    private var nextStateBeacon: BeaconMO?
    private var lastPlace: NSNumber?

    override public func didEnter(from previousState: GKState?) {
        if let place = self.place {
            Log.message("Enter Place \(place.name!)")
        }
     }
    
    override public func willExit(to nextState: GKState) {
        if let nextState = nextState as? InsideBeaconState {
            nextState.beacon = self.nextStateBeacon
        }
    }

    override public func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is InsideBeaconState.Type, is InsideRegionState.Type:
            return true
        default:
            return false
        }
    }
    
    let serialOperation = OperationQueue()

    override public func update(deltaTime seconds: TimeInterval) {
        Log.message("Inside Place State", enabled: true)
        if playerEntity.currentBeacon == nil {
            guard let name = self.place?.name else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                return
            }
            Log.message("Leaving Place \(name)", enabled: true)
            playerEntity.updateState(InsideRegionState.self)
        }
        else {
            serialOperation.maxConcurrentOperationCount = 1
            if let currentBeacon = playerEntity.currentBeacon {
                guard let lastPlace = self.lastPlace else {
                    self.lastPlace = currentBeacon.major
                    return
                }
                if lastPlace != currentBeacon.major  {
                    playerEntity.updateState(InsideRegionState.self)
                    self.lastPlace = currentBeacon.major
                }
                if let place = self.place, let placeAccuracy = place.accuracy {
                    if currentBeacon.accuracy > placeAccuracy.doubleValue  {
                        playerEntity.updateState(InsideRegionState.self)
                    }
                }

                let fetchBeaconOperation = FetchBeaconOperation(major: currentBeacon.major, minor: currentBeacon.minor)
                serialOperation.addOperation (fetchBeaconOperation)
                fetchBeaconOperation.fetchBeaconCompletionBlock = { (beacon) in
                    if let beacon = beacon {
                        Log.message("Outside Beacon \(beacon.name!) accuracy \(currentBeacon.accuracy)")
                        if currentBeacon.accuracy <= beacon.accuracy.doubleValue {
                            self.nextStateBeacon = beacon
                            self.playerEntity.updateState(InsideBeaconState.self)
                        }
                    }
                }
            }
            else {
                playerEntity.updateState(InsideRegionState.self)
            }
        }
    }
}

public class InsideBeaconState: PlayerState {
    
    public var beacon: BeaconMO!
    private var lastBeacon: (NSNumber, NSNumber)?
    
    override public func didEnter(from previousState: GKState?) {

         if let beacon = self.beacon, let name = beacon.name, let minor = beacon.minor {
            Log.message("Enter Beacon \(name), \(minor)")
        }
    }

    override public func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is InsidePlaceState.Type, is InsideRegionState.Type, is InsideBeaconState.Type:
            return true
        default:
            return false
        }
    }
    
    override public func update(deltaTime seconds: TimeInterval) {
        if let currentBeacon = playerEntity.currentBeacon {
            guard let lastBeacon = self.lastBeacon else {
                self.lastBeacon = (currentBeacon.major,currentBeacon.minor)
                if let lastBeacon = self.lastBeacon {
                    let major =  lastBeacon.0
                    let minor = lastBeacon.1
                    Log.message("Last Beacon \(major), \(minor)")
                }
                return
            }
            if lastBeacon.0 != currentBeacon.major || lastBeacon.1 != currentBeacon.minor {
                playerEntity.updateState(InsidePlaceState.self)
                self.lastBeacon = (currentBeacon.major,currentBeacon.minor)
            }
            if currentBeacon.accuracy > beacon.accuracy.doubleValue  {
                playerEntity.updateState(InsidePlaceState.self)
            }
        }
        else {
            playerEntity.updateState(InsideRegionState.self)
        }
    }
}
