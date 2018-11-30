//
//  BaseTableViewController.swift
//  District-1 Admin
//
//  Created by WCA on 8/14/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import MapKit

open class BaseTableViewController: UITableViewController {

	public var datasource: BaseDataSource!
	public var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "name", ascending: true)]

	public typealias FetchedObject = NSManagedObject
	
	public var fetchedResultsController: NSFetchedResultsController<NSManagedObject>? {
		get {
			return dataSource.fetchedResultsController
		}
	}
	
	open var dataSource: BaseDataSource! {
		didSet {
			self.tableView?.dataSource = dataSource
		}
	}
	
	public var fetchedObject: FetchedObject? {
		get {
			if let
				fetchedObjects: [FetchedObject] = fetchedResultsController?.fetchedObjects,
				let fetchedObject = fetchedObjects.first {
				return fetchedObject
			}
			return nil
		}
	}
	
	@IBOutlet public weak var nameTextField: UITextField!
	@IBOutlet open weak var cancelButton: UIBarButtonItem!
	@IBOutlet open weak var undoButton: UIBarButtonItem!
	@IBOutlet public weak var saveButton: UIBarButtonItem!
		
	public var responder: UIResponder?

	override open func viewDidLoad() {
        super.viewDidLoad()
		setup()
    }
	
	deinit {
		Log.message("Deinit")
	}

	override open func didReceiveMemoryWarning() {
		Log.message("didReceiveMemoryWarning: \((#file as NSString).lastPathComponent): \(#function)\n")
    }
	
	open func setup() {
		setupTableView()
	}
	
	func setupTableView() {
		tableView.estimatedRowHeight = 72.0
		tableView.rowHeight = UITableViewAutomaticDimension
		addLoadingView()
	}
	
	public func addLoadingView() {
		if tableView?.backgroundView == nil {
			let storyboard = UIStoryboard(name: "Loading", bundle: Bundle(identifier: "com.beaconcrawl.BeaconCrawl"))
			if let viewController = storyboard.instantiateInitialViewController() {
				let frame = self.view.frame
				tableView?.backgroundView = viewController.view
				tableView?.backgroundView?.frame = frame
			}
		}
	}
	
	public func removeLoadingView() {
		DispatchQueue.main.async {
			self.tableView?.backgroundView = nil
		}
	}
	
	// MARK: - Rotation
	//
	override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		let animationHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { [weak self] (context) in
			// This block will be called several times during rotation,
			// so if you want your tableView change more smooth reload it here too.
			self?.tableView.reloadData()
		}
		
		let completionHandler: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { [weak self] (context) in
			// This block will be called when rotation will be completed
			self?.tableView.reloadData()
		}
		
		coordinator.animate(alongsideTransition: animationHandler, completion: completionHandler)
		
	}

}

extension BaseTableViewController {
	
	// MARK: - TableViewDatasource
	open func cell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		return super.tableView(tableView, cellForRowAt: indexPath)
	}
	
	open func title(forHeaderInSection section: Int) -> String?  {
		return super.tableView(tableView, titleForHeaderInSection: section)
	}

	// MARK: - TableViewDelegate

	override open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return canEdit(rowAt: indexPath)
	}
	
	override open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return shouldIndentWhileEditing(rowAt: indexPath)
	}
	
	override open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return editingStyle(forRowAt: indexPath)
	}
	
	override open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		return shouldHighlight(rowAt: indexPath)
	}
	
	func canEdit(rowAt: IndexPath) -> Bool {
		return isEditing
	}
	
	func shouldIndentWhileEditing(rowAt: IndexPath) -> Bool {
		return false
	}
	
	func editingStyle(forRowAt: IndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.none
	}
	
	open func shouldHighlight(rowAt: IndexPath) -> Bool {
		return isEditing
	}
	
	// MARK: - Editing
	
	override open func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing != editing {
			super.setEditing(editing, animated: animated)
			updateTableView()
			if !editing {
				updateObject()
				if self.shouldSave() {
					if let objects = objects {
						DataManager.save(objects)
					}
				}
			}
		}
		updateEditingUI(isEditing: editing)
	}

	@objc open func updateEditingUI(isEditing: Bool) { }
	
	@objc open func updateTableView() { }

	@objc open func updateObject() {
		setSaveButtonState()
	}
	
	open func shouldSave() -> Bool {
		if let fetchedObject = fetchedObject {
			let changedValues = fetchedObject.changedValues()
			return !changedValues.isEmpty
		}
		return DataManager.viewContext.hasChanges || DataManager.backgroundContext.hasChanges
	}
	
	/// Disable the Save button if any of the text fields are empty.
	open func setSaveButtonState() {
		if let
			nameText = nameTextField.text {
			saveButton?.isEnabled = !nameText.isEmpty
		}
	}
	
	@IBAction func nextButtonPressed(withSender sender: AnyObject) {
		if let responder: UIResponder = self.responder {
			if let selectedView = responder as? UIView {
				let nextView = self.view.viewWithTag(selectedView.tag + 1)
				nextView?.becomeFirstResponder()
			}
		}
	}

	@IBAction func saveButtonPressed(withSender sender: UIBarButtonItem) {
		updateObject()
		if shouldSave() {
			if let objects = objects {
				DataManager.save(objects)
			}
		}
		navigationController?.popViewController(animated: true)
	}
	
	@IBAction func cancelButtonPressed(withSender sender: UIBarButtonItem) {
		if let fetchedObject = self.fetchedObject {
			DataManager.deleteObjects([fetchedObject], from: DataManager.Container.publicCloudDatabase)
		}
		tableView.reloadData()
		navigationController?.popViewController(animated: true)
	}
	
	@IBAction func undoButtonPressed(withSender sender: UIBarButtonItem) {
		if let fetchedObject = self.fetchedObject {
			update(with: [fetchedObject])
		}
		super.setEditing(false, animated: true)
		updateTableView()
		updateEditingUI(isEditing: false)
	}
}

extension BaseTableViewController: FetchedController {
	
	@objc open var request: NSFetchRequest<NSManagedObject>! {
		get {
			return self.request
		}
	}
	
	@objc open var query: CKQuery! {
		get {
			return self.query
		}
	}
	
	@objc open func update(with objects: [NSManagedObject]?) {
		updateViews()
	}
	
	@objc open func updateViews() {
		tableView.reloadData()
	}

	
	public var objects: [NSManagedObject]? {
		get {
			return dataSource.objects
		}
	}
	
}


extension BaseTableViewController: UITextFieldDelegate {
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return true
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		responder = textField
	}

	public func textFieldDidEndEditing(_ textField: UITextField) {
		setSaveButtonState()
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let view = self.view.viewWithTag(textField.tag + 1)
		view?.becomeFirstResponder()
		return false
	}
}

//MARK: - UITextViewDelegate

extension BaseTableViewController: UITextViewDelegate {
	
	open func textViewDidBeginEditing(_ textView: UITextView) {
		responder = textView
	}
	
	public func textViewDidEndEditing(_ textView: UITextView) {
		updateObject()
		setSaveButtonState()
	}
	
	open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		return true
	}
	
	open func textViewDidChange(_ textView: UITextView) {
		let size = textView.bounds.size;
		let newSize = textView.sizeThatFits(CGSize(width: size.width, height: size.height))
		
		if size.height != newSize.height {
			UIView.setAnimationsEnabled(false)
			self.tableView.beginUpdates()
			self.tableView.endUpdates()
			UIView.setAnimationsEnabled(true)
			
			let pointInTable = textView.convert(textView.bounds.origin, to: self.tableView)
			if let indexPath = self.tableView.indexPathForRow(at: pointInTable) {
				self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
			}
		}
	}
}

