//
//  AdventureDescriptionsDetailViewController.swift
//  District-1 Admin
//
//  Created by Bill A on 11/17/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import BeaconCrawl

class AdventureDescriptionsDetailViewController: BaseTableViewController, ImagePickerHelperDelegate  {
	
	typealias Object = AdventureDescriptionMO
	public var imageModified: Bool?
	public var queuedPagesIndexPaths = Set<IndexPath>()
	var adventure: AdventureMO?

    enum Section: Int {
		case description
        case image
        case remove
        case count
    }
    
    enum EditableImage: Int {
        case image
		case caption
        case name
        case count
    }
    
    enum Description: Int {
        case title
        case description
        case count
    }
    
    enum Remove: Int {
        case remove
        case count
    }
    
    // Image

    @IBOutlet weak var editableImageView: UIImageView!
    // Description
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionTextCell: UITableViewCell!
	@IBOutlet weak var captionTextCell: UITableViewCell!
	@IBOutlet weak var captionTextView: UITextView!
	
	var adventureDescription: Object? {
		get {
			return fetchedObject as? Object
		}
	}
	
	var recordID: CKRecord.ID!
	
	override func setup() {
		super.setup()
		setupViews()
		setupDatasource()
	}
	
    func setupViews() {
		nameTextField.delegate = self
		descriptionTextView.delegate = self
		titleTextField.delegate = self
        captionTextView.delegate = self
    }
	
	override func updateEditingUI(isEditing: Bool) {
		nameTextField.isEnabled = isEditing
		descriptionTextView.isEditable = isEditing
		titleTextField.isEnabled = isEditing
		captionTextView.isEditable = isEditing
		let section = Section.remove.rawValue
		if recordID != nil {
			if isEditing {
				navigationItem.leftBarButtonItem = undoButton
				tableView.beginUpdates()
				tableView.insertSections(IndexSet(integer: section), with: .fade)
				tableView.insertRows(at: [IndexPath(row: 0, section: section)], with: UITableView.RowAnimation.automatic)
				tableView.endUpdates()
			}
			else {
				navigationItem.rightBarButtonItem = editButtonItem
				editButtonItem.isEnabled = true
				navigationItem.leftBarButtonItem = nil
				self.responder?.resignFirstResponder()
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
	
	override func updateObject() {
		if let adventureDescription = adventureDescription {
			updateImage()
			if adventureDescription.name != nameTextField.text {
				adventureDescription.name = nameTextField.text
			}
			if adventureDescription.descriptiveText != descriptionTextView.text {
				adventureDescription.descriptiveText = descriptionTextView.text
			}
			if adventureDescription.titleText != titleTextField.text {
				adventureDescription.titleText = titleTextField.text
			}
			if adventureDescription.captionText != captionTextView.text {
				adventureDescription.captionText = captionTextView.text
			}
		}
	}
	
	override func updateViews() {
		guard let adventureDescription = self.adventureDescription else { return }
		nameTextField?.text = adventureDescription.name
		navigationItem.title = nameTextField?.text

		if let imageData = adventureDescription.imageData {
			editableImageView.image = UIImage(data: imageData)
		}
		captionTextView.text = adventureDescription.captionText
		titleTextField.text = adventureDescription.titleText
		descriptionTextView.text = adventureDescription.descriptiveText
	}
	
//	override func setEditing(_ editing: Bool, animated: Bool) {
//		super.setEditing(editing, animated: animated)
//		updateEditingUI()
//		if !isEditing {
//			updateObject()
//			if self.shouldSave() {
//				if let objects = objects {
//					DataManager.save(objects: objects, to: DataManager.Container.publicCloudDatabase)
//				}
//			}
//		}
//	}
	
	// MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch indexPath {
        case IndexPath(row: EditableImage.image.rawValue, section: Section.image.rawValue):
            selectImagePickerType(with: self)
        case IndexPath(row: Remove.remove.rawValue, section: Section.remove.rawValue):
            performSegue(withIdentifier: .delete, sender: cell)
        default:
            break
        }
    }
	
    // MARK: - UIImagePickerControllerDelegate
    
    func setup(imagePicker: UIImagePickerController) {
        imagePicker.allowsEditing = false
    }
    
	func imagePickerController(_ picker: UIImagePickerController,
							   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
			editableImageView.image = image
			if picker.sourceType == UIImagePickerController.SourceType.camera {
				UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
			}
			picker.dismiss(animated: true, completion: nil)
			imageModified = true
			setSaveButtonState()
		}
	}
	
	@IBAction func selectImagePickerType(withSender sender:AnyObject) {
		if responder != nil {
			responder!.resignFirstResponder()
		}
		ImagePickerHelper.selectImagePickerType(inPresentingViewController: self)
	}

    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableViewDatasource

extension AdventureDescriptionsDetailViewController {
	
	override var request: NSFetchRequest<NSManagedObject>! {
		guard let recordID = recordID else { return nil }
		let request:NSFetchRequest<Object> = Object.fetchRequest()
		request.sortDescriptors = sortDescriptors
		request.predicate = NSPredicate(format: "recordID == %@", recordID)
		request.fetchBatchSize = 1
		request.returnsObjectsAsFaults = false
		return request as? NSFetchRequest<NSManagedObject>
	}
	
	override var query: CKQuery! {
		let recordType = Object.recordType()
		guard let recordID = recordID else { return nil }
		let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "recordID == %@", recordID))
		return query
	}

	func setupDatasource() {
		if recordID == nil {
			isEditing = true
			let adventureDescription = DataManager.createManagedObject(forRecordType: Object.recordType()) as? Object
			adventureDescription?.adventure = adventure
			recordID = adventureDescription?.recordID
			dataSource = BaseDataSource(withFetchedController: self, request: request, query: query)
			tableView?.dataSource = dataSource
			dataSource.fetchLocal()
		}
		else {
			dataSource = BaseDataSource(withFetchedController: self, request: request, query: query)
			dataSource.fetchLocalCompletionBlock = { (adventureDescription) in
				self.updateViews()
				//self.dataSource.fetchRemote()
				if !self.isEditing {
					self.isEditing = false
				}
			}
			tableView?.dataSource = dataSource
			dataSource.fetchLocal()
		}
	}
	
	// MARK: - TableViewDatasource
	
	var numberOfSections:Int  {
		let count = Section.count.rawValue
		switch (isEditing) {
		case (false):
			return count - 1
		case (true):
			return count
		}
	}
	
	func numberOfRows(inSection section: Int) -> Int {
		let sectionIdentifier: Section = AdventureDescriptionsDetailViewController.Section(rawValue: section)!
		switch (sectionIdentifier, isEditing) {
		case (Section.image, _):
			return EditableImage.count.rawValue
		case (Section.description, _):
			return Description.count.rawValue
		case (Section.remove, true):
			return Remove.count.rawValue
		case (_, _):
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		switch indexPath {
		case IndexPath(row: EditableImage.image.rawValue, section: Section.image.rawValue):
			if let imageData = adventureDescription?.imageData, let image = UIImage(data:imageData){
				return image.size.height/UIScreen.main.scale
			}
			else {
				return UITableView.automaticDimension
			}
		default:
			return UITableView.automaticDimension
		}
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
}

extension AdventureDescriptionsDetailViewController: EditableImage {
	
	var database: CKDatabase! {
		return DataManager.Container.publicCloudDatabase
	}

    func updateImageView() {
        if
            let fetchedObject = self.fetchedObject as? Object,
            let imageData = fetchedObject.imageData {
            editableImageView.image = UIImage(data: imageData as Data) ?? UIImage(named: "Camera")
        }
    }
    
    func updateImage() {
        if imageModified == true {
            if
                let adventureDescription = self.adventureDescription,
                let image = editableImageView.image != UIImage(named:"Camera") ? editableImageView.image : nil {
                if let image = image.scale(width: 640, height: 640) {
                    adventureDescription.imageData = image.jpegData(compressionQuality:  0.5)
                }
            }
            imageModified = false
        }
    }

	public func selectImagePickerType(with sender:UIViewController) {
		if responder != nil {
			responder!.resignFirstResponder()
		}
		ImagePickerHelper.selectImagePickerType(inPresentingViewController: sender)
	}
}


//MARK: - UITextViewDelegate

/*extension PromotionalPageDetailViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView)    {
        let size = textView.bounds.size;
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: size.height))
		Log.message("New Size \(newSize)")
        
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            switch textView {
            case descriptionTextView:
                if let indexPath = tableView.indexPath(for: descriptionTextCell) {
                    tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
                }
			case captionTextView:
				if let indexPath = tableView.indexPath(for: captionTextCell) {
					tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
				}
            default:
                break
            }
			tableView.endUpdates()
			UIView.setAnimationsEnabled(true)
        }
    }
	
	public func textViewDidEndEditing(_ textView: UITextView) {
		updateObject()
		setSaveButtonState()
	}
	
	public func changeResponder(from textView: UITextView) -> Bool {
		let responder = self.view.viewWithTag(textView.tag + 1)
		responder?.becomeFirstResponder()
		return true
	}

	
//	public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
//		updateObject()
//		return true
//	}
}*/

extension AdventureDescriptionsDetailViewController: SegueHandlerType {
	enum SegueIdentifier: String {
		case delete = "delete"
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
			if let fetchedObject = fetchedObject {
				DataManager.deleteObjects([fetchedObject], from: DataManager.Container.publicCloudDatabase)
			}
		}
	}
}


