//
//  BeaconCrawlManager.swift
//  BeaconCrawl
//
//  Created by WCA on 10/14/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreLocation

open class BeaconCrawlManager: NSObject, BeaconDiscovery {
    
	public let locationManager =  CLLocationManager()
	public var currentLocation: CLLocation?
	
    // Register other managers as soon as possible after launch.
    // Must register to recieve silent push when there is new content
    public let notificationManager = NotificationManager.shared

    public static let shared = BeaconCrawlManager()
    
    public var player : PlayerEntity?

    fileprivate override init() {
        super.init()
		self.locationManager.delegate = self
    }
}

// MARK: - PlayerEntityDelegate

extension BeaconCrawlManager: PlayerEntityDelegate {
    
    public func playerEntity(_ entity: PlayerEntity, didChangeState state: PlayerState) {
        switch state {
        case is OutsideRegionState:
			break
		case is InsideRegionState:
            guard let beacon = entity.currentBeacon else { break }
            let fetchBeaconOperation = FetchBeaconOperation(major: beacon.major, minor: beacon.minor)
            fetchBeaconOperation.fetchBeaconCompletionBlock = { (beacon) in
                DispatchQueue.main.async {
                    if beacon != nil {
                        //self.setTitle(String.localizedStringWithFormat("District-1 — \(beaconObject.name!) %.2fm", beacon.accuracy))
                    }
                }
            }
            fetchBeaconOperation.start()
        case is InsidePlaceState:
			guard let beacon = entity.currentBeacon else { break }
            let fetchBeaconOperation = FetchBeaconOperation(major: beacon.major, minor: beacon.minor)
            fetchBeaconOperation.start()
            fetchBeaconOperation.fetchBeaconCompletionBlock = { (beacon) in
            }
        case is InsideBeaconState:
            guard let state = state as? InsideBeaconState else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                return
            }
            guard (state.beacon) != nil else {
                Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                return
            }
            guard entity.currentBeacon != nil else { break }
        default:
            break
        }
    }
 }

// MARK: - CLLocationManagerDelegate

extension BeaconCrawlManager: LocationManager {
	
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined:
			break
		case .authorizedWhenInUse:
			BeaconCrawlManager.shared.removeRegionDiscovery(for: manager)
			BeaconCrawlManager.shared.setupRangingDiscovery()
		case .authorizedAlways:
			BeaconCrawlManager.shared.removeRangingDiscovery()
			BeaconCrawlManager.shared.setupRegionDiscovery()
		case .restricted: break
			// restricted by e.g. parental controls. User can't enable Location Services
		case .denied:
			BeaconCrawlManager.shared.removeRangingDiscovery()
			BeaconCrawlManager.shared.removeRegionDiscovery(for: manager)
			// user denied your app access to Location Services, but can grant access from Settings.app
		}
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFail(with: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdate(locations: locations)
    }
    
	@objc public func updateLocation() { }
	
}


