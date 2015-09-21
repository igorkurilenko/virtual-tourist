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

func printError(error: NSError) {
    print(error)
}

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

class PageRandomizer {
    var pages = [Int]()
    var counter = 0
    
    func nextPage() -> Int {
        if(pages.count == 0){
            return 1
        }
        
        let maxIndexToPick = pages.count - counter
        let randomIndex = Int(arc4random_uniform(UInt32(maxIndexToPick)))
        
        return pickIndex(randomIndex)
    }
    
    private func pickIndex(index: Int) -> Int {
        let moveTo = min(pages.count - counter, pages.count - 1)
        let page = pages[index]
        pages[index] = pages[moveTo]
        pages[moveTo] = page
        
        counter = moveTo == 0 ? 0 : counter + 1
        
        return page
    }
    
    func reset(var totalPages: Int, lastLoadedPage: Int?) {
        if totalPages < 1 {
            totalPages = 1
        }
        
        pages = [Int](count: totalPages, repeatedValue: 1)
        counter = 0
        
        for i in 1...totalPages {
            pages[i - 1] = i
        }
        
        if lastLoadedPage != nil &&
            lastLoadedPage >= 1 &&
            lastLoadedPage <= totalPages {
                pickIndex(lastLoadedPage! - 1)
        }
    }
}
