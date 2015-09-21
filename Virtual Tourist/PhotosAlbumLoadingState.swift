//
//  PhotosAlbumLoadingState.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/19/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData

@objc(PhotosAlbumLoadingState)

class PhotosAlbumLoadingState: NSManagedObject {
    @NSManaged var inProgress: NSNumber
    @NSManaged var totalPages: NSNumber?
    @NSManaged var lastLoadedPage: NSNumber?
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("PhotosAlbumLoadingState", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        inProgress = NSNumber(bool: false)
    }
}