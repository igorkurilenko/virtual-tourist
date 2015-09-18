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

class MapViewController: BaseUIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    private var lastPin:Pin!
    private let mapRegionService = WithCurrentLocationDetectionIfNotExists(
        decoratee: MapRegionArchiverService())
    private lazy var fetchedPinsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.sharedDataContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedPinsController.performFetch()
        } catch _ {
        }
        
        initMapView()
    }
    
    private func initMapView() {
        initGestureRecognizer()
        initMapRegion()
        
        mapView.addAnnotations(fetchedPinsController.fetchedObjects as! [Pin])
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
            addPin(coordinate)
            
        case .Changed:
            let coordinate = getGestureCoordinate(gestureRecognizer)
            lastPin.coordinate = coordinate
            
        case .Ended:
            CoreDataStackManager.saveContext()
            searchPhotos(forPin: lastPin)
            
        default:
            return
        }
    }
    
    private func getGestureCoordinate(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let pressPoint = gestureRecognizer.locationInView(mapView)
        
        return mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
    }
    
    private func addPin(coordinate: CLLocationCoordinate2D) {
        lastPin = Pin(coordinate: coordinate, context: sharedDataContext)
        
        mapView.addAnnotation(lastPin)
    }
    
    // MARK: - Map view delegate
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegionService.persistMapRegion(mapView.region)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
        result.pinColor = MKPinAnnotationColor.Red
        
        return result
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let colletionViewController =
        storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController")
            as! CollectionViewController
        
        colletionViewController.pin = view.annotation as! Pin
        
        navigationController!.pushViewController(colletionViewController, animated: true)
        
        // In case if user goes back from collection view and then wants to open collection again.
        // If pin is selected it's impossible to open collection again.
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}

extension Pin: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude as Double, longitude: self.longitude as Double)
        }
        
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}





