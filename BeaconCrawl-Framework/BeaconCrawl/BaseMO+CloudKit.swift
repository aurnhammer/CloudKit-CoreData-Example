//
//  BaseMO+CloudKit.swift
//  Notifications
//
//  Created by WCA on 6/24/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import GameKit
import MapKit

extension BaseMO {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseMO> {
        return NSFetchRequest<BaseMO>(entityName: "Base")
    }
}

@objc(BaseMO)
open class BaseMO: NSManagedObject {

    open override func awakeFromInsert() {
        super.awakeFromInsert()
		if let record = self.entity.userInfo?["record"] as? CKRecord {
			self.addAttributes(from: record)
		}
	}
}

protocol ManagedObject {
	func addAttributes(from record: CKRecord, for keys: [String]?)
    func addAttributes(to record: CKRecord,for keys: [String])
}

extension NSManagedObject: ManagedObject {

	@NSManaged public var name: String?
    @NSManaged public var recordName: String!
	@NSManaged public var recordID: CKRecordID!
	@NSManaged public var recordChangeTag: String!
    @NSManaged public var data: Data!
	@NSManaged public var currentDistance: NSNumber?
	@NSManaged public var latitude: NSNumber?
	@NSManaged public var longitude: NSNumber?
	
	@objc open func addAttributes(from record: CKRecord, for keys: [String]? = nil) {
		
        recordName = record.recordID.recordName
        recordID = record.recordID
		// Updating the record causes NSFetchResultsController to inform the UI that the record has changed.
		// If the recordChange tag is the same as what's already in CoreData do not update the record.
		if let keys = keys, keys.isEmpty, record.recordChangeTag != nil, self.recordChangeTag == record.recordChangeTag {
			return
		}
		else {
			self.recordChangeTag = record.recordChangeTag
		}

		var keys = keys
		if keys == nil {
			keys = record.allKeys()
		}
		
		if keys!.contains("location"), let index = keys!.index(of: "location") {
			if let clLocation = record["location"] as? CLLocation {
				self.latitude = clLocation.coordinate.latitude as NSNumber
				self.longitude = clLocation.coordinate.longitude as NSNumber
			}
			if let location = BeaconCrawlManager.shared.locationManager.location {
				self.updateCurrentDistance(from: location)
			}
			
			keys!.remove(at: index)
		}
		
		for key in keys! {
			if let date = record[key] as? NSDate {
				self[key] = date
			}
			if let string = record[key] as? String {
				self[key] = string as NSString
			}
			if let number = record[key] as? NSNumber {
				self[key] = number
			}
			if let asset = record[key] as? CKAsset {
				self[key] = try? Data(contentsOf: asset.fileURL) as NSData
			}
		}
        // Encode the system fields of the record
        self.data = DataManager.dataFromRecord(record)
    }
	
	@objc open func addAttributes(to record:CKRecord, for keys: [String]) {
		
		var keys = keys
		
		if keys.contains("latitude") || keys.contains("longitude")  {
			record["location"] = self.location
			if let index = keys.index(of: "latitude") {
				keys.remove(at: index)
			}
			if let index = keys.index(of: "longitude") {
				keys.remove(at: index)
			}
		}
		
		keys = Array(Set(keys).subtracting( ["currentDistance", "data", "recordName", "recordID", "recordChangeTag"]))

		for key in keys {
			if let date = self[key] as? NSDate {
				record[key] = date
			}
			if let string = self[key] as? NSString {
				record[key] = string
			}
			if let number = self[key] as? NSNumber {
				record[key] = number
			}
			if let bool = self[key] as? Bool {
				record[key] = bool as NSNumber
			}
			if let data = self[key] as? Data {
				record[key] = try? CKAsset(data: data as Data)
			}
		}
    }
	
	subscript(key: String) -> NSObject? {
		get {
			return self.value(forKey: key) as? NSObject
		}
		set(newValue) {
			self.setValue(newValue, forKey: key)
		}
	}
	
	func allKeys() -> [String] {
		let propertiesByName = self.entity.propertiesByName
		return Array(propertiesByName.keys)
	}
	

	open func  updateCurrentDistance(from userLocation: CLLocation) {
		guard let latitude = self.latitude?.doubleValue else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		guard let longitude = self.longitude?.doubleValue else {
			Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
			return
		}
		let objectLocation: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
		if self.currentDistance != objectLocation.distance(from: userLocation) as NSNumber {
			self.currentDistance = objectLocation.distance(from: userLocation) as NSNumber
		}
	}
	
	var coordinate: CLLocationCoordinate2D? {
		guard let latitude = self.latitude?.doubleValue else { return nil }
		guard let longitude = self.longitude?.doubleValue else { return nil }
		return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	var location: CLLocation? {
		guard let latitude = self.latitude?.doubleValue else { return nil }
		guard let longitude = self.longitude?.doubleValue else { return nil }
		return CLLocation(latitude: latitude, longitude: longitude)
	}
}
