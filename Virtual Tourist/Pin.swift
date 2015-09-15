//
//  Pin.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/15/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject {
    
    @NSManaged var latitude:Double
    @NSManaged var longitude:Double
    @NSManaged var photos: [Photo]
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        
    }
}