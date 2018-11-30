//
//  MapViewController.swift
//  Notifications
//
//  Created by WCA on 6/14/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import MapKit
import CloudKit
import CoreData

public protocol MapViewDataSource : class {

	func createAnnotations() -> [Annotation]?
	func updateAnnotation(_ annotation: Annotation)
	func numberOfAnnotations() -> Int
	func objectForIndex (_ index: Int) -> NSManagedObject?
	
}

open class MapViewController : UIViewController, MKMapViewDelegate {
	
	@IBOutlet private weak var mapView: MKMapView!
	@IBOutlet private weak var trackingButtonView: UIView!
	@IBOutlet private weak var locationTarget: UIView?
	
	open var dataSource: MapViewDataSource?
	public let locationManager = CLLocationManager()
	open var currentLocation: CLLocation?
	private var isLocationTargetVisible: Bool!
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		self.setup()
	}
	
	deinit {
		teardownMapView()
	}
	
	override open func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		Log.message("didReceiveMemoryWarning \(self)")
	}
	
	// MARK: - Setup
	open func setup() {
		setupMapView()
		setupTrackingButton()
		registerAnnotationViewClasses()
		setupLocationTarget()
	}
	
	open func setupMapView() {
		checkAuthorizationAndSetupLocationManager(required:true)
		mapView?.showsUserLocation = true
		mapView?.showsScale = true
		mapView?.showsCompass = true
		mapView?.showsBuildings = true
		mapView?.showsPointsOfInterest = true
		mapView?.delegate = self
		mapView?.mapType = .mutedStandard
		locationManager.requestLocation()
	}
	
	func teardownMapView() {
		mapView?.delegate = nil
		if let annotations = mapView?.annotations {
			mapView?.removeAnnotations(annotations)
		}
		if let overlays = mapView?.overlays {
			mapView?.removeOverlays(overlays)
		}
		mapView?.showsUserLocation = false
		mapView?.showsScale = false
		mapView?.showsCompass = false
		mapView?.showsBuildings = false
		mapView?.showsPointsOfInterest = false
		switch mapView?.mapType {
		case MKMapType.hybrid?:
			mapView?.mapType = MKMapType.standard
		case MKMapType.standard?:
			mapView?.mapType = MKMapType.hybrid
		default:
			break
		}
		mapView?.removeFromSuperview()
		mapView = nil
	}
	
	public func setupTrackingButton() {
		let trackingButton = MKUserTrackingButton(mapView: mapView)
		trackingButtonView.addSubview(trackingButton)
	}
	
	public func setLocationTarget(visible: Bool) {
		isLocationTargetVisible = visible
	}
	
	private func setupLocationTarget() {
		locationTarget?.isHidden = !isLocationTargetVisible
	}
	
	public func registerAnnotationViewClasses() {
		mapView?.register(MarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
		mapView?.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
	}

	open func loadData() {
		guard let datasource: MapViewDataSource = self.dataSource else { return }
		guard let newAnnotations = datasource.createAnnotations() else { return }
		let currentAnnotations = mapView?.annotations.filter{$0 is Annotation} as? [Annotation]
		if let currentAnnotations = currentAnnotations {
			let currentLocations = currentAnnotations.map { $0.coordinate }
			let newLocations = newAnnotations.map { $0.coordinate }
			if !currentLocations.containsSameElements(newLocations){
				if let beforeAnnotations = mapView?.annotations, let beforeOverlays = mapView?.overlays {
					mapView?.removeAnnotations(beforeAnnotations)
					mapView?.removeOverlays(beforeOverlays)
				}
			}
		}
		if mapView?.userTrackingMode == MKUserTrackingMode.none {
			mapView?.showAnnotations(newAnnotations, animated: true)
		}
		else {
			mapView?.addAnnotations(newAnnotations)
		}
	}
		
	open func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		if currentLocation != nil, isLocationTargetVisible == true {
			// Center of Map is offset by 25 pixels. Recalc center region based on offset.
			let newCoordinate = move(coordinate: mapView.centerCoordinate, by: CGPoint(x: 0, y: 25))
			update(coordinate: newCoordinate)
		}
	}
	
	private func move(coordinate: CLLocationCoordinate2D, by offset: CGPoint) -> CLLocationCoordinate2D {
		var point = mapView.convert(coordinate, toPointTo: mapView)
		point.x += offset.x
		point.y += offset.y
		return mapView.convert(point, toCoordinateFrom: mapView)
	}

	open func update(coordinate: CLLocationCoordinate2D) {
		guard let dataSource: MapViewDataSource = self.dataSource,
			let beacon = dataSource.objectForIndex(0) as? BeaconMO else {
			return
		}
		beacon.latitude = NSNumber(value: coordinate.latitude)
		beacon.longitude = NSNumber(value: coordinate.longitude)
		let locationManager = BeaconCrawlManager.shared.locationManager
		guard let userLocation = locationManager.location  else {
			Log.message("Could not determine userLocation")
			return
		}
		beacon.updateCurrentDistance(from:userLocation)
	}
	
}

//extension MapViewController: FetchedController {
//
//	public func update(with objects: [NSManagedObject]?) {
//		loadData()
//	}
//
//}

// MARK: - CLLocationManagerDelegate

extension MapViewController: LocationManager {

	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdate(locations: locations)
	}

	public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
	}

	public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		didFail(with: error)
	}

	public func updateLocation() {
		loadData()
	}

}
