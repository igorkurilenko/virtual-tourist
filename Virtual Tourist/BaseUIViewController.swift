//
//  BaseUIViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/17/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class BaseUIViewController: UIViewController {
    internal let flickrService = FlickrService(urlSession: NSURLSession.sharedSession())
    internal lazy var sharedDataContext: NSManagedObjectContext = {
        
        return CoreDataStackManager.instance().managedObjectContext
        }()
    
    internal func searchPhotosFor(pin: Pin) {
        flickrService.searchPhotos(pin.coordinate, onError: printError) { searchResult in
            self.forEachPhotoDicitonaryInSearchResult(searchResult){ photoDictionary in
                self.ifPhotoDoesntExist(photoDictionary) {
                    Photo.create(photoDictionary, pin: pin, context: sharedDataContext)
                }
                
                CoreDataStackManager.saveContext()
            }
        }
    }
    
    private func forEachPhotoDicitonaryInSearchResult(searchResult: NSDictionary,
        statement: [String: AnyObject] -> Void) {
            if let photosDictionary = searchResult.valueForKey("photos") as? [String: AnyObject],
                let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                    for photoDictionary in photosArray {
                        statement(photoDictionary)
                    }
            }
    }
    
    private func ifPhotoDoesntExist(photoDictionary: [String: AnyObject], statement: () -> Void) {
        if let id = photoDictionary["id"] as? String {
            ifPhotoDoesntExist(id, statement: statement)
        }
    }
    
    private func ifPhotoDoesntExist(id: String, statement: () -> Void) {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1
        
        if sharedDataContext.countForFetchRequest(fetchRequest, error: nil) == 0 {
            statement()
        }
    }
    
    // todo: throw alert window
    private func printError(error: NSError) {
        print("ERROR: \(error)")
    }

}