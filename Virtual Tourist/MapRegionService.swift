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
    
    func getMapRegion() -> MKCoordinateRegion?
    
}

class MapRegionArchiverService: MapRegionService {
    
    private var mapRegionFilePath: String {
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    func persistMapRegion(region: MKCoordinateRegion) {
        let regionDictionary = [
            "latitude": region.center.latitude,
            "longitude": region.center.longitude,
            "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(regionDictionary, toFile: mapRegionFilePath)
    }
    
    func getMapRegion() -> MKCoordinateRegion? {
        var result:MKCoordinateRegion?
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String: AnyObject] {
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            result = MKCoordinateRegion(center: center, span: span)
        }
        
        return result
    }
}