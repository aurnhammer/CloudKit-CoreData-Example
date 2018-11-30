//
//  BlueToothManager.swift
//  BeaconCrawl
//
//  Created by WCA on 4/19/18.
//  Copyright © 2018 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

open class BlueToothManager: NSObject, CBPeripheralManagerDelegate {
	
	public static let shared = BlueToothManager()

	public var didUpdateState:((_ peripheral: CBPeripheralManager?) -> Swift.Void)?

	private var peripheralManager: CBPeripheralManager?
	
	public override init() {
		super.init()
		self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options:[CBPeripheralManagerOptionShowPowerAlertKey: true])
	}

	func createBeaconRegion(major: CLBeaconMajorValue, minor: CLBeaconMinorValue) -> CLBeaconRegion? {
		if	let proximityUUID = UUID(uuidString: "F7790E36-99C5-489E-BD86-582C745E9210") {
			let beaconID = "com.districtapp"
			return CLBeaconRegion(proximityUUID: proximityUUID, major: major, minor: minor, identifier: beaconID)
		}
		return nil
	}
	
	open func startAdvertising (majorValue: CLBeaconMajorValue, minorValue: CLBeaconMinorValue) {
		if let beaconRegion = self.createBeaconRegion(major: majorValue, minor: minorValue)  {
			let peripheralData = beaconRegion.peripheralData(withMeasuredPower: nil)
			peripheralManager?.startAdvertising(((peripheralData as NSDictionary) as! [String : Any]))
		}
	}
	
	open func stopAdvertising() {
		peripheralManager?.stopAdvertising()
	}
	
	open func isAdvertising() -> Bool {
		if let peripheralManager = self.peripheralManager {
				return peripheralManager.isAdvertising
		}
		return false
	}

	public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		Log.message("PeripheralManager State: \(peripheral.state)")
		self.didUpdateState?(peripheral)
	}
		
	public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
		Log.message("PeripheralManager Did Start Advertising: \(peripheral.state)")
	}

	

}
