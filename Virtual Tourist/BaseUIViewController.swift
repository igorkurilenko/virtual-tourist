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
    
    internal func searchPhotos(forPin pin: Pin) {
        // todo: handle case if more than requested count is returned
        flickrService.searchPhotos(pin.coordinate, onError: printError) { searchResult in
            dispatch_async(dispatch_get_main_queue()) {
                self.forEachPhotoDicitonaryInSearchResult(searchResult){ photoDictionary in
                    self.ifPhotoDoesntExist(photoDictionary) {
                        self.createPhoto(photoDictionary, pin: pin)
                    }
                }
                
                CoreDataStackManager.saveContext()
            }
        }
    }
    
    private func createPhoto(photoDictionary: [String: AnyObject], pin: Pin) {
        if let photo = Photo.create(photoDictionary, pin: pin, context: sharedDataContext) {
            downloadImage(forPhoto: photo)
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
    
    private func downloadImage(forPhoto photo: Photo) {
        if let nsUrl = NSURL(string: photo.url) {
            NSURLSession.sharedSession().downloadImage(nsUrl, onError: printError) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    photo.filePath = self.saveImage(image)
                    
                    CoreDataStackManager.saveContext()
                }
            }
        } else {
            // todo: handle invalid url case
        }
    }
    
    private func saveImage(image: UIImage) -> String {
        let fileName = NSUUID().UUIDString.stringByAppendingString(".png")
        let docsDirPath:NSString = CoreDataStackManager.instance().appDocumentsDirectory.path!
        let filePath = docsDirPath.stringByAppendingPathComponent(fileName)
        UIImagePNGRepresentation(image)!.writeToFile(filePath, atomically: true)
        
        return filePath
    }
    
    // todo: throw alert window
    private func printError(error: NSError) {
        print("ERROR: \(error)")
    }
    
}