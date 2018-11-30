//
//  RangingComponent.swift
//  Notifications
//
//  Created by WCA on 9/27/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import GameplayKit
import CoreLocation 

open class RangingComponent: GKComponent, CLLocationManagerDelegate {

    fileprivate let locationManager = CLLocationManager()
    fileprivate var rangedRegion: CLBeaconRegion!
    var sortedBeacons: [(NSNumber, [CLBeacon])] = []

    public convenience init(with beaconRegion: CLBeaconRegion) {
        self.init()
        self.rangedRegion = beaconRegion
        setUpLocationManager()
    }
    
    deinit {
		Log.message("Stop Ranging Beacons in Region \(String(describing: rangedRegion))", enabled: true)
        locationManager.stopRangingBeacons(in: rangedRegion)
    }
    
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.startRangingBeacons(in: rangedRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.message("Did Fail With Error:  \(error.localizedDescription)", enabled: true)
    }

    public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        Log.message("Ranging Component Monitoring Did Fail With Error:  \(error.localizedDescription) for Region: \(region)", enabled: true)
    }

    var lastUpdateTimeInterval: TimeInterval = 0

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let playerEntity: PlayerEntity = entity as? PlayerEntity else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
            return
        }
        let currentTime = NSDate().timeIntervalSince1970
        let deltaTime = currentTime - lastUpdateTimeInterval
        // The current time will be used as the last update time in the next execution of the method.
        lastUpdateTimeInterval = currentTime
        sortedBeacons = RangingComponent.sortBeacons(beacons)
        playerEntity.update(deltaTime: deltaTime)
      }
    
    /// Sorts the Ranged Beacons and returns an Array of Tuples sorted by Accuracy
    // The first value represents the major value of the group of Beacons
    // The second value is an Array of Beacons, within each group, sorted by Accuracy
	public static func sortBeacons(_ beacons: [CLBeacon]) -> [(NSNumber, [CLBeacon])] {
        
        guard !beacons.isEmpty else {
            return []
        }
        
        // Filter out unwanted values
        let filteredBeacons = beacons.filter {$0.accuracy > 0 && $0.proximity != CLProximity.unknown}
        // Create a Array of Tuples of Beacon Objects using the Major value as the Key
        // Map the Major Value as the Key and remove duplicates. Iterate over the result
        var rangedBeacons: [(NSNumber, [CLBeacon])] = []
        for key in Array(Set(filteredBeacons.map{$0.major})) {
            var beacons = filteredBeacons.filter {$0.major == key}
            beacons.sort{$0.accuracy < $1.accuracy}
            rangedBeacons.append((key, beacons))
        }
        rangedBeacons.sort{$0.1.first!.accuracy < $1.1.first!.accuracy}
        
        Log.message("Did Range Beacons", enabled: false)
        for (key, beacons) in rangedBeacons {
            Log.message("\(key)", enabled: false)
            for beacon in beacons {
                Log.message("\(beacon)", enabled: false)
            }
        }
        return rangedBeacons
    }
}
