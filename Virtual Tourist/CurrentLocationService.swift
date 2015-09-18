//
//  CurrentLocationService.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/15/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import MapKit

class CurrentLocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var callback: ((currentCoordinate: CLLocationCoordinate2D?)->Void)!
    
    class func instance() -> CurrentLocationService {
        struct Static {
            static let instance = CurrentLocationService()
        }
        
        return Static.instance
    }
    
    private override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        
        if(CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        }
    }
    
    func get(callback: (currentCoordinate: CLLocationCoordinate2D?)->Void) {
        if(!CLLocationManager.locationServicesEnabled()) {
            print("location services not enabled")
            callback(currentCoordinate: nil)
        }
        
        self.callback = callback
        
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Location manager delegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        callback(currentCoordinate: locationManager.location!.coordinate)

        locationManager.stopUpdatingLocation()
    }

}