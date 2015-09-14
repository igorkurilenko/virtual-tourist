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

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private let mapRegionService = MapRegionArchiverService()
    private var lastPoinAnnotation:MKPointAnnotation?
    private lazy var sharedDataContext: NSManagedObjectContext = {
        
        return CoreDataStackManager.instance().managedObjectContext
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureGestureRecognizer()
        
        if let region = mapRegionService.getMapRegion() {
            mapView.setRegion(region, animated: false)
            
        }  else {
            setMapRegionByCurrentLocation()
        }
    }
    
    private func configureGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "onLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func setMapRegionByCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        
        if(CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.startUpdatingLocation()
        }
    }
    
    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            let coordinate = getGestureCoordinate(gestureRecognizer)
            addPointAnnotation(coordinate)
            
        case .Changed:
            let coordinate = getGestureCoordinate(gestureRecognizer)
            lastPoinAnnotation?.coordinate = coordinate
            
        default:
            return
        }
    }
    
    private func getGestureCoordinate(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let pressPoint = gestureRecognizer.locationInView(mapView)
        return mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
    }
    
    func addPointAnnotation(coordinate: CLLocationCoordinate2D) {
        lastPoinAnnotation = MKPointAnnotation()
        lastPoinAnnotation!.coordinate = coordinate
        
        mapView.addAnnotation(lastPoinAnnotation)
    }
    
    // MARK: - Map view delegate
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        mapRegionService.persistMapRegion(mapView.region)
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var result:MKAnnotationView!
        let reuseId = "com.virtual-tourist.pin"
        
        if let annotationView = getReusableAnnotationView(reuseId) {
            annotationView.annotation = annotation
            result = annotationView
            
        } else {
            result = createAnnotationView(annotation, reuseId: reuseId)
        }
        
        return result
    }
    
    private func getReusableAnnotationView(reuseId: String) -> MKPinAnnotationView? {
        return mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
    }
    
    private func createAnnotationView(annotation: MKAnnotation, reuseId: String) -> MKPinAnnotationView {
        let result = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        result!.pinColor = .Purple
        
        return result
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        views.first?.setSelected(true, animated: false)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("select")
    }
    
    
    
    // MARK: - Location manager delegate
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        mapView.setCenterCoordinate(locationManager.location.coordinate, animated: false)
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
}








