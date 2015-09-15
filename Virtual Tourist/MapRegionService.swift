//
//  MapRegionService.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/14/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import MapKit

protocol MapRegionService {

    func persistMapRegion(region: MKCoordinateRegion)
    
    func getMapRegion(callback: (MKCoordinateRegion?)->Void)
    
}

class MapRegionArchiverService: MapRegionService {
    
    private struct ArchiverTokens {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }
    
    private var mapRegionFilePath: String {
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    func persistMapRegion(region: MKCoordinateRegion) {
        let regionDictionary = [
            ArchiverTokens.Latitude: region.center.latitude,
            ArchiverTokens.Longitude: region.center.longitude,
            ArchiverTokens.LatitudeDelta: region.span.latitudeDelta,
            ArchiverTokens.LongitudeDelta: region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(regionDictionary, toFile: mapRegionFilePath)
    }
    
    func getMapRegion(callback: (MKCoordinateRegion?)->Void) {
        var result:MKCoordinateRegion?
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String: AnyObject] {
            let latitude = regionDictionary[ArchiverTokens.Latitude] as! CLLocationDegrees
            let longitude = regionDictionary[ArchiverTokens.Longitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let latitudeDelta = regionDictionary[ArchiverTokens.LatitudeDelta] as! CLLocationDegrees
            let longitudeDelta = regionDictionary[ArchiverTokens.LongitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            result = MKCoordinateRegion(center: center, span: span)
        }
        
        callback(result)
    }
}

class MapRegionServiceDecorator: MapRegionService {
    private var decoratee: MapRegionService
    
    init(decoratee: MapRegionService){
        self.decoratee = decoratee
    }
    
    func persistMapRegion(region: MKCoordinateRegion) {
        decoratee.persistMapRegion(region)
    }
    
    func getMapRegion(callback: (MKCoordinateRegion?) -> Void) {
        decoratee.getMapRegion(callback)
    }
}

class WithCurrentLocationDetectionIfNotExists: MapRegionServiceDecorator {
    
    private let currentLocationService = CurrentLocationService.instance()
    
    override func getMapRegion(callback: (MKCoordinateRegion?) -> Void) {
        decoratee.getMapRegion { region in
            if region != nil {
                callback(region)

            } else {
                self.getMapRegionByCurrentLocation(callback)
            }
        }
    }
    
    private func getMapRegionByCurrentLocation(callback: (MKCoordinateRegion?)->Void) {
        currentLocationService.get { currentCoordinate in
            if let coordinate = currentCoordinate {
                let region = self.createMapRegion(coordinate)
                
                callback(region)
                
            } else {
                callback(nil)
            }
        }
    }
    
    private func createMapRegion(center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
