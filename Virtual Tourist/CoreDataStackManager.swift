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
    lazy var appDocumentsDirectory:NSURL = {
        let fileManager = NSFileManager.defaultManager(),
        urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        return urls.last!
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
        let store: NSPersistentStore?
        do {
            store = try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeUrl, options: nil)
        } catch var error1 as NSError {
            error = error1
            store = nil
        } catch {
            fatalError()
        }
        
        assert(store != nil, "Unresolved error \(error?.localizedDescription), \(error?.userInfo)\n Attempt to create store at \(self.storeUrl)")
        
        return coordinator
    }()
    
    lazy var managedObjectContext:NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
//        managedObjectContext.retainsRegisteredObjects = true
        
        return managedObjectContext
    }()        
}