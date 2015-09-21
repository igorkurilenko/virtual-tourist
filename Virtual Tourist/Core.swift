//
//  Core.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/19/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation
import CoreData

class Core {
    class func instance() -> Core {
        struct Static {
            static let instance = Core()
        }
        
        return Static.instance
    }
    
    // Configure all dependencies here
    
    lazy var coreDataStackManager: CoreDataStackManager = {
        return CoreDataStackManager()
    }()
    
    lazy var sharedUrlSession: NSURLSession = {
        return NSURLSession.sharedSession()
    }()
    
    private lazy var flickrClient: FlickrClient = {
        return DefaultFlickrClient(urlSession: self.sharedUrlSession)
    }()
    
    lazy var remoteDataProvider: RemoteDataProvider = {
        return RandomFlickrRemoteDataProvider(flickrClient: self.flickrClient)
    }()
}