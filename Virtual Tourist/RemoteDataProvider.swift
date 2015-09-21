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
    func loadPhotos(forPin pin: Pin, context: NSManagedObjectContext, onError: OnError)
    
    func cancelLoading(forPin pin: Pin)
    
    func cancelImageDownloading(forPin pin: Pin, forPhoto photo: Photo)
    
    func createLoadingContext(forPin pin: Pin) -> LoadingContext
}

protocol LoadingContext {
    var pin: Pin { get }
    
    var loadPhotos: ((NSManagedObjectContext, OnError) -> Void)! { get }
    
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
    
    func loadPhotos(forPin pin: Pin, context: NSManagedObjectContext, onError: OnError) {
        if contextByCoordinate[pin.coordinate] == nil {
            contextByCoordinate[pin.coordinate] = createLoadingContext(forPin: pin)
        }
        
        contextByCoordinate[pin.coordinate]!.loadPhotos(context, onError)
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
    private let pageRandomizer = PageRandomizer()
    var pin: Pin
    var loadPhotos: ((NSManagedObjectContext, OnError) -> Void)!
    static let SearchPhotosPerPage = 21
    static let FlickrDoesNotAllowToSearchMore = 4000
    
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
    
    func indeedLoadPhotos(context: NSManagedObjectContext, onError: OnError) {
        let pageToLoad = getRandomPageToLoad(pin.photosAlbumLoadingState)
        let decoratedOnError = decorateOnError(onError, pin: pin, context: context)
        
        searchPhotosAndDownloadImages(forPin: pin,
            page: pageToLoad,
            context: context,
            onError: decoratedOnError)
    }
    
    private func decorateOnError(onError: OnError, pin: Pin, context: NSManagedObjectContext) -> OnError {
        return { error in
            self.didSearchPhotos(forPin: pin, context: context)
            
            onError(error)
        }
    }
    
    private func willSearchPhotos(forPin pin: Pin, context: NSManagedObjectContext) {
        // to prevent redudant requests (do not load photos if photos are being loaded)
        loadPhotos = dummyLoadPhotos
        
        dispatch_async(dispatch_get_main_queue()) {
            pin.photosAlbumLoadingState.inProgress = true
            
            saveCoreDataContext(context)
        }
    }
    
    private func didSearchPhotos(forPin pin: Pin, context: NSManagedObjectContext) {
        dispatch_async(dispatch_get_main_queue()) {
            pin.photosAlbumLoadingState.inProgress = false
            
            saveCoreDataContext(context)
            
            self.searchPhotosTask = nil
            
            self.loadPhotos = self.indeedLoadPhotos
        }
    }
    
    
    private func searchPhotosAndDownloadImages(forPin pin: Pin, page: Int,
        context: NSManagedObjectContext, onError: OnError) {
            willSearchPhotos(forPin: pin, context: context)
            
            searchPhotosTask = flickrClient.searchPhotos(pin.coordinate,
                page: page, perPage: RandomFlickrLoadingContext.SearchPhotosPerPage,
                onError: onError) { searchResult in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.forEachPhotoDicitonaryInSearchResult(searchResult){ photoDictionary in
                            self.ifPhotoDoesntExist(photoDictionary, context: context) {
                                if let photo = Photo.create(photoDictionary, pin: pin, context: context) {
                                    self.downloadImage(forPhoto: photo, context: context)
                                }
                            }
                        }
                        
                        self.updatePhotosAlbumLoadingState(searchResult, pin: pin, context: context)
                        
                        self.didSearchPhotos(forPin: pin, context: context)
                    }
            }
    }
    
    private func updatePhotosAlbumLoadingState(searchResult: NSDictionary, pin: Pin, context: NSManagedObjectContext) {
        if let photosDictionary = searchResult.valueForKey("photos") as? [String: AnyObject],
            let totalPagesInResponse = photosDictionary["pages"] as? Int,
            let lastLoadedPage = photosDictionary["page"] as? Int {
                let totalPages = min((RandomFlickrLoadingContext.FlickrDoesNotAllowToSearchMore /
                    RandomFlickrLoadingContext.SearchPhotosPerPage) + 1,
                    totalPagesInResponse)
                
                pin.photosAlbumLoadingState.totalPages = totalPages
                pin.photosAlbumLoadingState.lastLoadedPage = lastLoadedPage
        }
    }
    
    private func downloadImage(forPhoto photo: Photo, context: NSManagedObjectContext) {
        if let nsUrl = NSURL(string: photo.url) {
            let task = Core.instance().sharedUrlSession.downloadImage(nsUrl, onError: printError) { image in
                self.didDownloadImage(image, forPhoto: photo, context: context)
            }
            
            imageDownloadingTasks[photo.id] = task
        }
    }
    
    private func didDownloadImage(image: UIImage, forPhoto photo: Photo, context: NSManagedObjectContext) {
        dispatch_async(dispatch_get_main_queue()) {
            self.imageDownloadingTasks.removeValueForKey(photo.id)
            
            photo.filePath = self.saveImage(image)
            
            saveCoreDataContext(context)
        }
    }
    
    private func saveImage(image: UIImage) -> String {
        let fileName = NSUUID().UUIDString.stringByAppendingString(".png")
        let docsDirPath:NSString = Core.instance().coreDataStackManager.appDocumentsDirectory.path!
        let filePath = docsDirPath.stringByAppendingPathComponent(fileName)
        UIImagePNGRepresentation(image)!.writeToFile(filePath, atomically: true)
        
        return filePath
    }
    
    func dummyLoadPhotos(context: NSManagedObjectContext, onError: OnError) {}
}

extension RandomFlickrLoadingContext {
    private func getRandomPageToLoad(photosAlbumLoadingState: PhotosAlbumLoadingState?) -> Int {
        if let totalPages = photosAlbumLoadingState?.totalPages as? Int {
            if totalPages != pageRandomizer.pages.count {
                pageRandomizer.reset(totalPages, lastLoadedPage: photosAlbumLoadingState?.lastLoadedPage?.integerValue)
            }
        }
        
        return pageRandomizer.nextPage()
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
















