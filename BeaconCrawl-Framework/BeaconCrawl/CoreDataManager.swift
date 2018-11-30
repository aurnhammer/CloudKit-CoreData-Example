//
//  CoreDataManager.swift
//  Notifications
//
//  Created by WCA on 6/18/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

open class CoreDataManager: NSObject {
	
    // MARK: - SHARED INSTANCE
	public static let shared = CoreDataManager()
	
	public lazy var persistentContainer: NSPersistentContainer = {
			var supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
			
			let storeURL = supportDirectory.appendingPathComponent("BeaconCrawl.sqlite")
			let assetURL = supportDirectory.appendingPathComponent(".BeaconCrawl_SUPPORT")
			
			var isDirectory: ObjCBool = true
			if !FileManager.default.fileExists(atPath: supportDirectory.path, isDirectory: &isDirectory) {
				do {
					try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: false, attributes: nil)
				}
				catch {
					fatalError("Failed to create Support Directory: \(error)")
				}
				var resourceValues = URLResourceValues()
				resourceValues.isExcludedFromBackup = true
				try? supportDirectory.setResourceValues(resourceValues)
			}
			
			/* Copy the default store (with a pre-populated data) into our Documents folder.*/
			
			/* if the expected store doesn't exist, copy the default store */
			if !FileManager.default.fileExists(atPath: storeURL.path), let defaultStorePath = Bundle.main.path(forResource: "Application Support/BeaconCrawl", ofType: "sqlite") {
				do {
					try FileManager.default.copyItem(atPath: defaultStorePath, toPath: storeURL.path)
					
				} catch {
					fatalError("Failed to copy store: \(error)")
				}
				let directory = Bundle.main.resourceURL!.appendingPathComponent("Application Support/.BeaconCrawl_SUPPORT").path
				
				do {
					try FileManager.default.copyItem(atPath: directory, toPath: assetURL.path)
				} catch {
					fatalError("Failed to copy store: \(error)")
				}
			}
			
			/*
			The persistent container for the application. This implementation
			creates and returns a container, having loaded the store for the
			application to it. This property is optional since there are legitimate
			error conditions that could cause the creation of the store to fail.
			*/
			let bundle: Bundle = Bundle(for: type(of: self).self)
			// This resource is the same name as your xcdatamodeld contained in your project.
			guard let modelURL = bundle.url(forResource:"BeaconCrawl", withExtension: "momd")
				else {
					fatalError("Error loading model from bundle")
			}
			let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
			
			let container = NSPersistentContainer(name: "BeaconCrawl", managedObjectModel: managedObjectModel!)
			
			let storeDescription = NSPersistentStoreDescription(url: storeURL)
			storeDescription.shouldInferMappingModelAutomatically = true
			storeDescription.shouldMigrateStoreAutomatically = true
			
			container.persistentStoreDescriptions = [storeDescription]
			
			container.loadPersistentStores(completionHandler: { (storeDescription, error) in
				if let error = error as NSError? {
					// Replace this implementation with code to handle the error appropriately.
					// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
					
					/*
					Typical reasons for an error here include:
					* The parent directory does not exist, cannot be created, or disallows writing.
					* The persistent store is not accessible, due to permissions or data protection when the device is locked.
					* The device is out of space.
					* The store could not be migrated to the current model version.
					Check the error message to determine what the actual problem was.
					*/
					fatalError("Unresolved error \(error), \(error.userInfo)")
				}
			})
			return container
	}()
	
	public func createPersistentContainer() -> NSPersistentContainer {
		
		var supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
		
		let storeURL = supportDirectory.appendingPathComponent("BeaconCrawl.sqlite")
		let assetURL = supportDirectory.appendingPathComponent(".BeaconCrawl_SUPPORT")
		
		var isDirectory: ObjCBool = true
		if !FileManager.default.fileExists(atPath: supportDirectory.path, isDirectory: &isDirectory) {
			do {
				try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: false, attributes: nil)
			}
			catch {
				fatalError("Failed to create Support Directory: \(error)")
			}
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = true
			try? supportDirectory.setResourceValues(resourceValues)
		}
		
		/* Copy the default store (with a pre-populated data) into our Documents folder.*/
		
		/* if the expected store doesn't exist, copy the default store */
		if !FileManager.default.fileExists(atPath: storeURL.path), let defaultStorePath = Bundle.main.path(forResource: "Application Support/BeaconCrawl", ofType: "sqlite") {
			do {
				try FileManager.default.copyItem(atPath: defaultStorePath, toPath: storeURL.path)
				
			} catch {
				fatalError("Failed to copy store: \(error)")
			}
		}
		
		if !FileManager.default.fileExists(atPath: assetURL.path) {
			let directory = Bundle.main.resourceURL!.appendingPathComponent("Application Support/.BeaconCrawl_SUPPORT").path

			do {
				try FileManager.default.copyItem(atPath: directory, toPath: assetURL.path)
			} catch {
				fatalError("Failed to copy store: \(error)")
			}
		}
		
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let bundle: Bundle = Bundle(for: type(of: self).self)
		// This resource is the same name as your xcdatamodeld contained in your project.
		guard let modelURL = bundle.url(forResource:"BeaconCrawl", withExtension: "momd")
			else {
				fatalError("Error loading model from bundle")
		}
		let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
		
		let container = NSPersistentContainer(name: "BeaconCrawl", managedObjectModel: managedObjectModel!)
		
		let storeDescription = NSPersistentStoreDescription(url: storeURL)
		storeDescription.shouldInferMappingModelAutomatically = true
		storeDescription.shouldMigrateStoreAutomatically = true
		
		container.persistentStoreDescriptions = [storeDescription]
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		return container
	}
 }

