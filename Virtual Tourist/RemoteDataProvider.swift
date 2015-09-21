//
//  VirtualTouristRemoteDataProvider.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/19/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

protocol RemoteDataProvider {
    /// Load photos and download relative images.
    /// Implied to use fetched results controller delegate
    /// to handle a photos load complete event.
    func loadPhotos(forPin pin: Pin, context: NSManagedObjectContext)
    
    func cancelLoading(forPin pin: Pin)

    func cancelImageDownloading(forPin pin: Pin, forPhoto photo: Photo)
    
    func createLoadingContext(forPin pin: Pin) -> LoadingContext
}

protocol LoadingContext {
    var pin: Pin { get }
    
    var loadPhotos: ((NSManagedObjectContext) -> Void)! { get }
    
    func cancelLoading()
    
    func cancelImageDownloading(forPhoto photo: Photo)
}

/// Every load fetches a random page of photos from flickr
class RandomFlickrRemoteDataProvider: RemoteDataProvider {
    private let flickrClient:FlickrClient
    private var contextByCoordinate = [CLLocationCoordinate2D:LoadingContext]()
    
    init(flickrClient: FlickrClient){
        self.flickrClient = flickrClient
    }
    
    func loadPhotos(forPin pin: Pin, context: NSManagedObjectContext) {
        if contextByCoordinate[pin.coordinate] == nil {
            contextByCoordinate[pin.coordinate] = createLoadingContext(forPin: pin)
        }
        
        contextByCoordinate[pin.coordinate]!.loadPhotos(context)
    }
    
    func cancelLoading(forPin pin: Pin) {
        contextByCoordinate[pin.coordinate]?.cancelLoading()
        contextByCoordinate.removeValueForKey(pin.coordinate)
    }
    
    func cancelImageDownloading(forPin pin: Pin, forPhoto photo: Photo) {
        contextByCoordinate[pin.coordinate]?.cancelImageDownloading(forPhoto: photo)
    }
    
    func createLoadingContext(forPin pin: Pin) -> LoadingContext {
        return RandomFlickrLoadingContext(pin: pin, flickrClient: flickrClient)
    }
}

/// Every load fetches a random page of photos from flickr
class RandomFlickrLoadingContext: LoadingContext {
    private var searchPhotosTask: NSURLSessionDataTask?
    private var imageDownloadingTasks = [String: NSURLSessionTask]()
    private let flickrClient:FlickrClient
    var pin: Pin
    var loadPhotos: ((NSManagedObjectContext) -> Void)!
    
    init(pin: Pin, flickrClient: FlickrClient) {
        self.pin = pin
        self.flickrClient = flickrClient
        loadPhotos = indeedLoadPhotos
    }
    
    func cancelLoading() {
        searchPhotosTask?.cancel()
        searchPhotosTask = nil
        
        cancelAllImagesDownloading()
    }
    
    private func cancelAllImagesDownloading() {
        for downloadTask in imageDownloadingTasks.values {
            downloadTask.cancel()
        }
        
        imageDownloadingTasks.removeAll()
    }
    
    func cancelImageDownloading(forPhoto photo: Photo) {
        imageDownloadingTasks[photo.id]?.cancel()
        imageDownloadingTasks.removeValueForKey(photo.id)
    }
    
    func indeedLoadPhotos(context: NSManagedObjectContext) {
        willLoadPhotos(forPin: pin, context: context)
        
        let pageToLoad = getRandomPageToLoad(pin.photosAlbumLoadingState)
        
        loadPhotos(forPin: pin, page: pageToLoad, context: context)
    }
    
    private func willLoadPhotos(forPin pin: Pin, context: NSManagedObjectContext) {
        loadPhotos = dummyLoadPhotos
        
        dispatch_async(dispatch_get_main_queue()) {
            pin.photosAlbumLoadingState.inProgress = true
            
            saveCoreDataContext(context)
        }
    }
    
    private func loadPhotos(forPin pin: Pin, page: Int, context: NSManagedObjectContext) {
        // todo: handle case if more than requested count is returned
        searchPhotosTask = flickrClient.searchPhotos(pin.coordinate, page: page, onError: printError) { searchResult in
            dispatch_async(dispatch_get_main_queue()) {
                self.forEachPhotoDicitonaryInSearchResult(searchResult){ photoDictionary in
                    self.ifPhotoDoesntExist(photoDictionary, context: context) {
                        if let photo = Photo.create(photoDictionary, pin: pin, context: context) {
                            self.downloadImage(forPhoto: photo, context: context)
                        }
                    }
                }
                
                self.didLoadPhotos(forPin: pin, searchResult: searchResult, context: context)
            }
        }
    }
    
    private func didLoadPhotos(forPin pin: Pin, searchResult: NSDictionary, context: NSManagedObjectContext) {
        updatePhotosAlbumLoadingState(searchResult, pin: pin, context: context)
        
        saveCoreDataContext(context)
        
        loadPhotos = indeedLoadPhotos
    }
    
    private func updatePhotosAlbumLoadingState(searchResult: NSDictionary, pin: Pin, context: NSManagedObjectContext) {
        if let photosDictionary = searchResult.valueForKey("photos") as? [String: AnyObject],
            let totalPages = photosDictionary["pages"] as? Int,
            let lastLoadedPage = photosDictionary["page"] as? Int {
                pin.photosAlbumLoadingState.totalPages = totalPages
                pin.photosAlbumLoadingState.lastLoadedPage = lastLoadedPage
                pin.photosAlbumLoadingState.inProgress = false
                
        } else {
            // todo: handle this case
        }
    }
    
    private func downloadImage(forPhoto photo: Photo, context: NSManagedObjectContext) {
        if let nsUrl = NSURL(string: photo.url) {
            let task = Core.instance().sharedUrlSession.downloadImage(nsUrl, onError: printError) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    photo.filePath = self.saveImage(image)
                    
                    saveCoreDataContext(context)
                }
            }
            
            imageDownloadingTasks[photo.id] = task
        } else {
            // todo: handle invalid url case
        }
    }
    
    private func saveImage(image: UIImage) -> String {
        let fileName = NSUUID().UUIDString.stringByAppendingString(".png")
        let docsDirPath:NSString = Core.instance().coreDataStackManager.appDocumentsDirectory.path!
        let filePath = docsDirPath.stringByAppendingPathComponent(fileName)
        UIImagePNGRepresentation(image)!.writeToFile(filePath, atomically: true)
        
        return filePath
    }
    
    // todo: throw alert window
    private func printError(error: NSError) {
        print("ERROR: \(error)")
    }
    
    func dummyLoadPhotos(context: NSManagedObjectContext) {}
}

extension RandomFlickrLoadingContext {
    private func getRandomPageToLoad(photosAlbumLoadingState: PhotosAlbumLoadingState?) -> Int {
        if let lastLoadedPage = photosAlbumLoadingState?.lastLoadedPage as? Int {
            // todo: implement random number generation based on pages total
            return lastLoadedPage + 1
            
        } else {
            return 1
        }
    }
}

extension RandomFlickrLoadingContext {
    private func forEachPhotoDicitonaryInSearchResult(searchResult: NSDictionary,
        statement: [String: AnyObject] -> Void) {
            if let photosDictionary = searchResult.valueForKey("photos") as? [String: AnyObject],
                let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                    for photoDictionary in photosArray {
                        statement(photoDictionary)
                    }
            }
    }
    
    private func ifPhotoDoesntExist(photoDictionary: [String: AnyObject], context: NSManagedObjectContext, statement: () -> Void) {
        if let id = photoDictionary["id"] as? String {
            ifPhotoDoesntExist(id, context: context, statement: statement)
        }
    }
    
    private func ifPhotoDoesntExist(id: String, context: NSManagedObjectContext, statement: () -> Void) {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1
        
        if context.countForFetchRequest(fetchRequest, error: nil) == 0 {
            statement()
        }
    }
}