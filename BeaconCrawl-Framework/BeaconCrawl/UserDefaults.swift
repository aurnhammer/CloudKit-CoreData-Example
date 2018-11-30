//
//  UserDefaults.swift
//  BeaconCrawl
//
//  Created by WCA on 5/3/17.
//  Copyright © 2017 aurnhammer.com. All rights reserved.
//

import UIKit

public struct Defaults {
    public static let subscriptions = "Subscriptions"
}

public extension UserDefaults {

    public class func updateUserDefaults(with value: Any, forKey key: String) {

        var set: Set<AnyHashable>
        if let array = UserDefaults.standard.array(forKey: key) as? [AnyHashable] {
            set = Set(array)
        }
        else { set = Set() }
        set.insert(value as! AnyHashable)
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.set(Array(set), forKey: key)
        UserDefaults.standard.synchronize()
    }

    public class func contains(_ value: Any, for key: String) -> Bool {
        guard let array = UserDefaults.standard.array(forKey: key) as? [AnyHashable], let value: AnyHashable = value as? AnyHashable else { return false }
        return array.contains(value)
    }
}

extension UserDefaults {
	
	public class func update(withDictionary newDictionary: [String : Any], forName name: String) {
		guard let newDictionaryValue = Array(newDictionary.values).first else { return }
		guard let newDictionaryKey = Array(newDictionary.keys).first else { return }
		
		var dictionary: [String : Any]? = UserDefaults.standard.dictionary(forKey: name)
		if dictionary == nil {
			dictionary = [:]
		}
		let data = NSKeyedArchiver.archivedData(withRootObject: newDictionaryValue)
		dictionary?.updateValue(data, forKey: newDictionaryKey)
		UserDefaults.standard.removeObject(forKey: name)
		UserDefaults.standard.set(dictionary, forKey: name)
		UserDefaults.standard.synchronize()
	}
	
	
	public class func value(forKey key: String, withName name: String) -> Any? {
		guard let dictionary = UserDefaults.standard.dictionary(forKey: name) else { return false }
		let databaseKeys = Array(dictionary.keys)
		if databaseKeys.contains(key), let data = dictionary[key] as? Data {
			return NSKeyedUnarchiver.unarchiveObject(with: data)
		}
		return nil
	}
}

