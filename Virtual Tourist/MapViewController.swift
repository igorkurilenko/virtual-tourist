//
//  MasterViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private let fileManager = NSFileManager.defaultManager()
    var mapRegionFilePath: String {
        let url = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        
        return url.URLByAppendingPathComponent("mapRegion").path!
    }
    
    lazy var sharedDataContext: NSManagedObjectContext = {
       return CoreDataStackManager.instance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureGestureRecognizer()
        
        
        if fileManager.fileExistsAtPath(mapRegionFilePath) {
            restoreMapRegion()
        
        } else {
            configureLocationManager()
        }
    }
    
    private func configureGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "onLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }

    private func configureLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        
        if(CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.startUpdatingLocation()
        }
    }
    
    func pin(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
    }
    
    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let pressPoint = gestureRecognizer.locationInView(mapView)
        let pressCoordinate = mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
        
        pin(pressCoordinate)
    }
    
    func saveMapRegion() {
        let region = mapView.region

        let regionDictionary = [
            "latitude": region.center.latitude,
            "longitude": region.center.longitude,
            "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(regionDictionary, toFile: mapRegionFilePath)
    }
    
    func restoreMapRegion() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String: AnyObject] {
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let region = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(region, animated: false)
        }
    }
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Purple
            
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        mapView.setCenterCoordinate(locationManager.location.coordinate, animated: false)
        locationManager.stopUpdatingLocation()
    }
}










