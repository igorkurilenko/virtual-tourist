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

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!    
    private let mapRegionService = WithCurrentLocationDetectionIfNotExists(decoratee: MapRegionArchiverService())
    private var lastPointAnnotation:MKPointAnnotation?
    private lazy var sharedDataContext: NSManagedObjectContext = {
        
        return CoreDataStackManager.instance().managedObjectContext
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initMapView()
    }
    
    private func initMapView() {
        initGestureRecognizer()
        
        initMapRegion()
    }
    
    private func initGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "onLongPress:")
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func initMapRegion() {
        mapRegionService.getMapRegion { mapRegion in
            if let mapRegion = mapRegion {
                self.mapView.setRegion(mapRegion, animated: true)
            }
        }
    }
    
    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            let coordinate = getGestureCoordinate(gestureRecognizer)
            addPointAnnotation(coordinate)
            
        case .Changed:
            let coordinate = getGestureCoordinate(gestureRecognizer)
            lastPointAnnotation?.coordinate = coordinate
            
        default:
            return
        }
    }
    
    private func getGestureCoordinate(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let pressPoint = gestureRecognizer.locationInView(mapView)
        return mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
    }
    
    func addPointAnnotation(coordinate: CLLocationCoordinate2D) {
        lastPointAnnotation = MKPointAnnotation()
        lastPointAnnotation!.coordinate = coordinate
        
        mapView.addAnnotation(lastPointAnnotation)
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
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }
    
}








