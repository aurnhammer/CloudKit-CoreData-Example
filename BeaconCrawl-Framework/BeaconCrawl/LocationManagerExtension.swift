//
//  LocationManagerExtension.swift
//  District1
//
//  Created by WCA on 11/21/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit


extension Array where Element: Comparable {
	public func containsSameElements(_ other: [Element]) -> Bool {
		return self.count == other.count && self.sorted() == other.sorted()
	}
}

extension CLLocationCoordinate2D: Comparable {
	public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return (fabs(lhs.latitude - rhs.latitude) < .ulpOfOne) && (fabs(lhs.longitude - rhs.longitude) < .ulpOfOne)
	}
	
	public static func < (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return lhs.latitude < rhs.latitude ||
			(lhs.latitude == rhs.latitude && lhs.longitude < rhs.longitude) ||
			(lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
	}
}

// MARK: - CLLocationManagerDelegate

@objc public protocol LocationManager: CLLocationManagerDelegate {
	var locationManager: CLLocationManager { get }
	var currentLocation: CLLocation? { get set }
	@objc func updateLocation()
	@objc optional var view: UIView!  { get }
}

public extension LocationManager {
	
	//(meters/mile * 3000 miles) the width of the United States  1609.34 * 3000.0

	public var  radius: Double {
		return 1609.34 * 3000.0
	}
	
	func checkAuthorizationAndSetupLocationManager(required isRequired: Bool? = false) {
		
		self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		self.locationManager.distanceFilter = 100
		self.locationManager.delegate = self
		
		switch CLLocationManager.authorizationStatus() {
		case .authorizedWhenInUse:
			self.locationManager.requestWhenInUseAuthorization()
		case .authorizedAlways:
			self.locationManager.requestAlwaysAuthorization()
		case .notDetermined:
			if let isRequired = isRequired, isRequired == true {
				self.locationManager.requestWhenInUseAuthorization()
			}
		case .denied, .restricted:
			if let isRequired = isRequired, isRequired == true {
				askForWhenInUseAuthorization()
			}
		}
	}
	
	
	public func askForWhenInUseAuthorization() {
		if let currentViewController = self as? UIViewController {
			let alertController = UIAlertController(
				title: "Allow Location Access",
				message: "To see adventures near you based on distance, please open this app's settings and set location access to 'While Using the App'.",
				preferredStyle: .alert)
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			alertController.addAction(cancelAction)
			
			let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
				if let url = URL(string:UIApplicationOpenSettingsURLString) {
					UIApplication.shared.open(url, options: [:], completionHandler:nil)
				}
			}
			alertController.addAction(openAction)
			if let presentedViewController = currentViewController.presentedViewController {
				presentedViewController.present(alertController, animated: true, completion: nil)
			}
			else {
				currentViewController.present(alertController, animated: true, completion: nil)
			}
		}
	}
	
	public func askForAlwaysAuthorizationStatus() {
		switch CLLocationManager.authorizationStatus() {
		case .authorizedAlways: break
		case .notDetermined:
			locationManager.requestAlwaysAuthorization()
		case .authorizedWhenInUse, .restricted, .denied:
			let alertController = UIAlertController(
				title: "Background Location Access Disabled",
				message: "In order to be notified about adventures near you, please open this app's settings and set location access to 'Always'.",
				preferredStyle: .alert)
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			alertController.addAction(cancelAction)
			
			let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
				if let url = URL(string:UIApplicationOpenSettingsURLString) {
					UIApplication.shared.open(url, options: [:], completionHandler:nil)
				}
			}
			alertController.addAction(openAction)
			if let
				appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
				let window = appDelegate.window,
				let rootViewController = window!.rootViewController {
				rootViewController.present(alertController, animated: true, completion: nil)
			}
		}
	}
	
	func didFail(with error: Error) {
		Log.error(with: #line, functionName: #function, error: error)
	}
	
	func didUpdate(locations: [CLLocation]) {
		if !locations.isEmpty {
			let filteredDistance: CLLocationDistance = 50
			Log.message("Pre Filter Location: \(String(describing: locations.last))", enabled: false)
			if let newLocation: CLLocation = locations.last {
				// Needed to filter cached and too old locations
				var distance: CLLocationDistance = filteredDistance
				if currentLocation != nil {
					distance = currentLocation!.distance(from: newLocation)
				}
				let howRecent: TimeInterval = abs(newLocation.timestamp.timeIntervalSinceNow)
				if (howRecent < 15 && distance >= filteredDistance) || currentLocation == nil {
					currentLocation = newLocation;
					updateLocation()
				}
			}
		}
	}
	
	func updateUIForLocation(location: CLLocation) {
	}
}

extension CLLocationManager {
	// MARK: - Location Helper Predicates
	open class func predicateBoundingBoxFromLocation(_ location:CLLocation, withRadius radius:Double) -> NSPredicate {
		let center:CLLocationCoordinate2D = location.coordinate;
		let region:MKCoordinateRegion  = MKCoordinateRegionMakeWithDistance(center, radius, radius)
		let max:CLLocationCoordinate2D = CLLocationCoordinate2DMake(center.latitude  + (region.span.latitudeDelta), center.longitude + (region.span.longitudeDelta))
		let min:CLLocationCoordinate2D = CLLocationCoordinate2DMake(center.latitude  - (region.span.latitudeDelta), center.longitude - (region.span.longitudeDelta))
		
		return NSPredicate(format:"%f < latitude and %f > latitude and %f < longitude and %f > longitude", min.latitude, max.latitude, min.longitude, max.longitude)
	}
}

