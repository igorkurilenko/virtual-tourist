//
//  Utils.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/17/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData
import MapKit

typealias OnError = (NSError) -> Void

func ifErrorElse(error: NSError?, errorHandler: OnError, noErrorHandler: () -> Void) {
    if let error = error {
        errorHandler(error)
        
    } else {
        noErrorHandler()
    }
}

func saveCoreDataContext(context: NSManagedObjectContext) {
    if !context.hasChanges {
        return
    }
    
    do {
        try context.save()
    } catch let error as NSError {
        print("Error saving context: \(error.localizedDescription)\n\(error.userInfo)", terminator: "")
    }
}

extension CLLocationCoordinate2D: Hashable {
    public var hashValue: Int {
        return latitude.hashValue ^ longitude.hashValue
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
}