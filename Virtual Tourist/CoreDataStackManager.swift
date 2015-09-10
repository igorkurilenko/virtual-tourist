//
//  CoreDataStackManager.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData

let SQLITE_FILE_NAME = "Virtual_Tourist.sqlite"

class CoreDataStackManager {
    class func instance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    lazy var appDocumentsDirectory:NSURL = {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        return urls[urls.count-1] as! NSURL
    }()
    
    lazy var storeUrl:NSURL = {
        return self.appDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
    }()
    
    lazy var managedObjectModel:NSManagedObjectModel = {
        let mainBundle =  NSBundle.mainBundle()
        let modelDescriptionUrl = mainBundle.URLForResource("Virtual_Tourist", withExtension: "momd")!
        
        return NSManagedObjectModel(contentsOfURL: modelDescriptionUrl)!
    }()
    
    lazy var persistentStoreCoordinator:NSPersistentStoreCoordinator = {
        let coordinator:NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var error: NSError? = nil
        let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeUrl, options: nil, error: &error)
        
        assert(store != nil, "Unresolved error \(error?.localizedDescription), \(error?.userInfo)\n Attempt to create store at \(self.storeUrl)")
        
        return coordinator
    }()
    
    lazy var managedObjectContext:NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    func saveContext() {
        if !self.managedObjectContext.hasChanges {
            return
        }
        
        var error: NSError? = nil
        if self.managedObjectContext.save(&error) {
            return
        }
        
        print("Error saving context: \(error?.localizedDescription)\n\(error?.userInfo)")
    }
    
}