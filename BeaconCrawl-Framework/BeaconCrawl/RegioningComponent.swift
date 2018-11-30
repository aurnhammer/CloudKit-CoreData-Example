//
//  RegioningComponent.swift
//  Notifications
//
//  Created by WCA on 6/26/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import GameplayKit
import CoreLocation

open class RegioningComponent: GKComponent, CLLocationManagerDelegate {
    
    /**
     Controls the states of the experience.
    */
    let locationManager = CLLocationManager()
    var beaconRegion: CLBeaconRegion!

    public convenience init(with beaconRegion: CLBeaconRegion) {
        self.init()
        self.beaconRegion = beaconRegion
        setUpLocationManager()
    }
    
    deinit {
		Log.message("Stop Regioning Beacons in Region \(String(describing: beaconRegion))")
        self.locationManager.stopMonitoring(for: beaconRegion)
    }
    
    func setUpLocationManager() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
        startMonitoring()
    }
    
    func startMonitoring () {
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true;
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.requestState(for: beaconRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.message("Did Fail With Error:  \(error.localizedDescription)", enabled: true)
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Log.message("Regioning Component Monitoring Did Fail With Error:  \(error.localizedDescription) for Region: \(String(describing: region))", enabled: true)
    }
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Log.message("Did Start Monitoring For Region \(region)", enabled: true)
    }
    
    // MARK: - Did Determine State
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let region: CLBeaconRegion = region as? CLBeaconRegion else {return}
        guard let playerEntity: PlayerEntity = entity as? PlayerEntity else {return}
        switch state {
        case .inside:
            // We are in the Region
            playerEntity.updateState(InsideRegionState.self)
			Log.message("We are inside Region \(region)")
        case .outside:
            // We have exited our Region
            playerEntity.updateState(OutsideRegionState.self)
			playerEntity.currentBeacon = nil
			Log.message("We have left Region \(region)")
        case .unknown:
            Log.message("State Unknown Region \(region)")
        }
    }
}
