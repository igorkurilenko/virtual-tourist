//
//  Photo.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/15/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)

class Photo: NSManagedObject {    
    @NSManaged var id: NSNumber
    @NSManaged var url: String
    @NSManaged var filePath: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(id: NSNumber, url: String, filePath: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = id
        self.url = url
        self.filePath = filePath
    }
}