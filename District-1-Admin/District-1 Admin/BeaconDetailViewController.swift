//
//  BeaconDetailViewController.swift
//  District-1 Admin
//
//  Created by WCA on 11/12/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import BeaconCrawl
import CloudKit
import CoreData
import CoreBluetooth
import CoreLocation

class BeaconDetailViewController: BaseTableViewController {
	
    typealias Object = BeaconMO
	
	enum Section: Int {
		case edit
		case remove
		case count
	}
	
	enum Edit: Int {
		case name
		case major
		case minor
		case accuracy
		case location
		case enabled
		case count
	}

	enum Remove: Int {
		case remove
		case count
	}
	
	@IBOutlet weak var majorTextField: UITextField!
	@IBOutlet weak var minorTextField: UITextField!
	@IBOutlet weak var accuracyTextField: UITextField!
	@IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var nextAccessoryView: UIView!
	@IBOutlet weak var beaconSwitch: UISwitch!
	
	var beacon: Object? {
		get {
			return fetchedObject as? Object
		}
	}
	
	var coreBlueToothManager: BlueToothManager = BlueToothManager.shared
	
	var recordID: CKRecord.ID!
	var isEnabled: Bool = false

	deinit {
		Log.message("Deinit")
		coreBlueToothManager.stopAdvertising()
	}
	
	override func setup() {
		super.setup()
		setupViews()
		setupDatasource()
	}
	
	func setupViews() {
		nameTextField.delegate = self
		minorTextField.delegate = self
		accuracyTextField.delegate = self
		majorTextField?.inputAccessoryView = nextAccessoryView
		minorTextField?.inputAccessoryView = nextAccessoryView
		accuracyTextField?.inputAccessoryView = nextAccessoryView
	}
	
	override func updateEditingUI(isEditing: Bool) {
		nameTextField.isEnabled = isEditing
		majorTextField.isEnabled = isEditing
		majorTextField.isEnabled = isEditing
		minorTextField.isEnabled = isEditing
		accuracyTextField.isEnabled = isEditing
		locationTextField.isEnabled = isEditing
		let section = Section.remove.rawValue
		if recordID != nil {
			if isEditing {
				navigationItem.leftBarButtonItem = undoButton
				guard tableView.numberOfSections == 1 else {
					return
				}
				tableView.beginUpdates()
				tableView.insertSections(IndexSet(integer: section), with: .fade)
				tableView.insertRows(at: [IndexPath(row: 0, section: section)], with: UITableView.RowAnimation.automatic)
				tableView.endUpdates()
			}
			else {
				navigationItem.rightBarButtonItem = editButtonItem
				editButtonItem.isEnabled = true
				navigationItem.leftBarButtonItem = nil
				responder?.resignFirstResponder()
				guard tableView.numberOfSections > 1 else {
					return
				}
				tableView.beginUpdates()
				tableView.deleteSections(IndexSet(integer: section), with: .fade)
				tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: UITableView.RowAnimation.automatic)
				tableView.endUpdates()
			}
		}
		else if !isEditing {
			navigationItem.leftBarButtonItem = nil
			navigationItem.setHidesBackButton(false, animated: true)
			navigationItem.rightBarButtonItem = editButtonItem
			editButtonItem.isEnabled = true
		}
		else {
			navigationItem.leftBarButtonItem = cancelButton
		}
	}

	
	/// Don't change the managed object unless there is new data so we don't trigger an unneccesary network save
	override func updateObject() {
		if let beacon = beacon {
			if let
				nameText = nameTextField.text {
				if beacon.name != nameText {
					beacon.name = nameText
					self.navigationItem.title = beacon.name ?? "Beacon"
				}
			}
			
			if let
				minorText = minorTextField.text,
				let number = Int(minorText) {
				if beacon.minor != NSNumber(value: number as Int) {
					beacon.minor = NSNumber(value: number as Int)
				}
			}
			if let
				majorText = majorTextField.text,
				let number = Int(majorText) {
				if beacon.major != NSNumber(value: number as Int) {
					beacon.major = NSNumber(value: number as Int)
				}
			}
			if let
				accuracyTextField = accuracyTextField.text,
				let number = Double(accuracyTextField) {
				if beacon.accuracy != NSNumber(value: number as Double) {
					beacon.accuracy = NSNumber(value: number as Double)
				}
			}
		}
	}
	
	override func updateViews() {
		DispatchQueue.main.async { [unowned self] in
			guard let beacon = self.beacon else { return }
			self.nameTextField?.text = beacon.name ?? nil
			self.majorTextField?.text = beacon.major?.stringValue ?? nil
			self.minorTextField?.text = beacon.minor?.stringValue ?? nil
			self.accuracyTextField?.text = beacon.accuracy?.stringValue ?? nil
			if let longitude = beacon.longitude?.doubleValue,
				let latitude = beacon.latitude?.doubleValue {
				self.locationTextField.text = String(format: "Lat: %.4f Long: %.4f", latitude, longitude)
			}
		}
	}

	// MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch indexPath {
        case IndexPath(row: 0, section: Section.remove.rawValue):
            performSegue(withIdentifier: .delete, sender: cell)
        default:
            break
        }
    }
}

// MARK: - TableViewDatasource

extension BeaconDetailViewController {
	
	func setupDatasource() {
		if recordID == nil {
			isEditing = true
			guard let beacon = DataManager.createManagedObject(forRecordType: Object.recordType(), in: DataManager.viewContext) as? Object else {
				return
			}
			recordID = beacon.recordID
			removeLoadingView()
		}
		let dataSource = BeaconsDataSource(withFetchedController: self, recordID: recordID)
		self.dataSource = dataSource
		bindDataSource()
		dataSource.fetchData()
	}
	
	private func bindDataSource() {
		// When Prop changed, do something in the closure
		guard let dataSource = dataSource as? BeaconsDataSource else {
			return
		}
		dataSource.removeLoadingView = { [weak self] in
			DispatchQueue.main.async {
				self?.removeLoadingView()
			}
		}
		dataSource.reloadView = {
			self.updateViews()
			if !self.isEditing {
				self.isEditing = false
			}
		}
	}

	
	var numberOfSections:Int  {
		switch isEditing {
		case false:
			return 1
		case true:
			return 2
		}
	}
	
	func numberOfRows(inSection section: Int) -> Int {
		let edit = Section.edit.rawValue
		let remove = Section.remove.rawValue
		switch (section, isEditing) {
		case (edit, _):
			return Edit.count.rawValue
		case (remove, true):
			return Remove.count.rawValue
		case (_, _):
			return 0
		}
	}
}

extension BeaconDetailViewController: SegueHandlerType {
	
	enum SegueIdentifier: String {
		case delete = "delete"
		case map = "map"
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier,
			let sequeIndentifier = SegueIdentifier(rawValue:identifier)
			else {
				fatalError("Invalid Segue Identifier \(String(describing: segue.identifier))")
		}
		switch sequeIndentifier {
		case .delete:
			if let beacon = self.beacon {
				DataManager.deleteObjects([beacon], from: DataManager.Container.publicCloudDatabase)
			}
		case .map:
			if let destinationViewController: BeaconCrawl.MapViewController = segue.destination as? BeaconCrawl.MapViewController {
				if let _: BeaconDetailViewController = sender as?
					BeaconDetailViewController {
					destinationViewController.isEditing = false
				}
				else {
					destinationViewController.isEditing = true
				}
				destinationViewController.navigationItem.leftBarButtonItem = nil
				destinationViewController.navigationItem.rightBarButtonItem = nil
				destinationViewController.dataSource = dataSource as? MapViewDataSource
				destinationViewController.setLocationTarget(visible: true)
			}
		}
	}
	
	@IBAction func unwindToBeaconDetailViewController(withSegue segue: UIStoryboardSegue?) {
		tableView.reloadData()
	}
	
	func createBeaconRegion() -> CLBeaconRegion? {
		let proximityUUID = UUID(uuidString:
			"39ED98FF-2900-441A-802F-9C398FC199D2")
		let major : CLBeaconMajorValue = 100
		let minor : CLBeaconMinorValue = 1
		let beaconID = "com.example.myDeviceRegion"
		
		return CLBeaconRegion(proximityUUID: proximityUUID!,
							  major: major, minor: minor, identifier: beaconID)
	}
	
	@IBAction func setBeaconEnabled(_ sender: UISwitch) {
		switch sender.isOn {
		case true:
			self.startAdvertising()
		case false:
			self.stopAdvertising()
		}
	}
	
	
	func startAdvertising() {
		if coreBlueToothManager.isAdvertising() {
			coreBlueToothManager.stopAdvertising()
		}
		if let majorString = majorTextField.text,
			let major = CLBeaconMajorValue(majorString),
			let minorString = minorTextField.text,
			let minor = CLBeaconMinorValue(minorString) {
			coreBlueToothManager.startAdvertising(majorValue: major, minorValue: minor)
		}
	}
	
	func stopAdvertising() {
		coreBlueToothManager.stopAdvertising()
	}

	override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		self.performSegue(withIdentifier: .map, sender: self)
	}
	
}
