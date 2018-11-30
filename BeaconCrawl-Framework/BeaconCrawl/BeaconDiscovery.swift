//
//  BeaconDiscovery.swift
//  District1
//
//  Created by WCA on 11/21/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import CoreLocation

public protocol BeaconDiscovery: PlayerEntityDelegate {
    var player: PlayerEntity? { get set }
}

public extension BeaconDiscovery {
    
    fileprivate var UUID01: String {
        get {
            return "F7790E36-99C5-489E-BD86-582C745E9210"
        }
    }
    
    fileprivate var UUID02: String  {
        get {
            return "FED2AFFF9-0C58-4246-8483-CDE7B6F19A19"
        }
    }
	
	public func setupRegionDiscovery() {
		AccountManager.fetchUser(completionHandler: { (user) in
			DispatchQueue.main.async {
				if let user = user {
					let beaconRegion = CLBeaconRegion(proximityUUID:UUID(uuidString: self.UUID01)!, identifier: "com.beaconcrawl")
					let regioningComponent = RegioningComponent(with: beaconRegion)
					self.player = PlayerEntity(with:user, component: regioningComponent)
					self.player?.delegate = self
				}
			}
		})
	}
	
	public func setupRangingDiscovery() {
		AccountManager.fetchUser(completionHandler: { (user) in
			if let user = user {
				DispatchQueue.main.async {
					let beaconRegion = CLBeaconRegion(proximityUUID:UUID(uuidString: self.UUID01)!, identifier: "com.beaconcrawl")
					let rangingComponent = RangingComponent(with: beaconRegion)
					self.player = PlayerEntity(with:user, component: rangingComponent)
					self.player?.delegate = self
					self.player?.stateMachine.enter(InsideRegionState.self)
				}
			}
		})
	}

	public func removeRangingDiscovery() {
		self.player?.removeComponent(ofType: RangingComponent.self)
	}
	
	public func removeRegionDiscovery(for locationManager: CLLocationManager) {
		self.player?.removeComponent(ofType: RegioningComponent.self)
		for monitoredRegion in locationManager.monitoredRegions {
			locationManager.stopMonitoring(for: monitoredRegion)
		}
	}
	
    func didChange(_ state: PlayerState) {
        switch state {
        case is OutsideRegionState:
        	break
        case is InsideRegionState:
            guard let beacon = player?.currentBeacon else { break }
            let fetchBeaconOperation = FetchBeaconOperation(major: beacon.major, minor: beacon.minor)
            fetchBeaconOperation.start()
         case is InsidePlaceState:
           guard let beacon = player?.currentBeacon else { break }
            let fetchBeaconOperation = FetchBeaconOperation(major: beacon.major, minor: beacon.minor)
            OperationQueue().addOperation (fetchBeaconOperation)
 
		case is InsideBeaconState:
			guard let state = state as? InsideBeaconState else {
				Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
				return
			}
			guard (state.beacon) != nil else {
				Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
				return
			}
			guard player?.currentBeacon != nil else { break }
		default:
			break
		}
	}
}
