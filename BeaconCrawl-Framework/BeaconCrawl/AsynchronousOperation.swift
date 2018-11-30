//
//  AsynchronousOperation.swift
//  Notifications
//
//  Created by WCA on 9/21/16.
//  Copyright © 2016 aurnhammer.com. All rights reserved.
//

import UIKit

extension NSLock {
	func withCriticalScope<T>(_ block: () -> T) -> T {
		lock()
		let value = block()
		unlock()
		return value
	}
}

open class AsynchronousOperation: Operation {
	
	// use the KVO mechanism to indicate that changes to "state" affect other properties as well
	class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
		return ["state" as NSObject]
	}
	
	class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
		return ["state" as NSObject]
	}
	
	class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
		return ["state" as NSObject]
	}

	/// Private storage for the `state` property that will be KVO observed.
	private var _state = State.finished

	/// A lock to guard reads and writes to the `_state` property
	private let stateLock = NSLock()

	public enum State: Int {
		case executing
		case finished
		case cancelled
}

	open override var isExecuting: Bool {
		get {
			return state == .executing
		}
	}
	
	open override var isFinished: Bool {
		get {
			return state  ==  .finished || self.isCancelled
		}
	}
	
	open override var isCancelled: Bool {
		get {
			return state  ==  .cancelled
		}
	}
	
	open var state: State {
		get {
			return stateLock.withCriticalScope {
				_state
			}
		}
		
		set(newState) {
			
			stateLock.withCriticalScope { () -> Void in
				guard _state != .finished else {
					return
				}
				willChangeValue(forKey: "state")
				_state = newState
				didChangeValue(forKey: "state")
			}
			
		}
	}
	
	open func state(_ state: State) {
		self.state = state
	}
	
	open override var isAsynchronous: Bool {
		get {
			return true
		}
	}
	
	open override func start() {
		guard !isCancelled else {
			state(.cancelled)
			return
		}
		self.state(.executing)
		// If the operation is not canceled, begin executing the task.
		DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
			self.main()
		}
	}
}
