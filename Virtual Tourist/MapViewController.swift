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
    private var lastPin:Pin?
    private let flickrService = FlickrService(urlSession: NSURLSession.sharedSession())
    private let mapRegionService = WithCurrentLocationDetectionIfNotExists(
        decoratee: MapRegionArchiverService())
    
    private lazy var sharedDataContext: NSManagedObjectContext = {
        
        return CoreDataStackManager.instance().managedObjectContext
        }()
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: false)]
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.sharedDataContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initFetchedResultsController()
        initMapView()
    }
    
    private func initFetchedResultsController() {
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)
    }
    
    private func initMapView() {
        initGestureRecognizer()
        initMapRegion()
        mapView.addAnnotations(fetchedResultsController.fetchedObjects)        
    }
    
    private func printError(error: NSError) {
        println("ERROR: \(error)")
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
            lastPin?.coordinate = coordinate
            
        case .Ended:
            CoreDataStackManager.saveContext()
            // todo: prefetch photos
            
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
        result!.pinColor = MKPinAnnotationColor.Red
        
        return result
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        views.first?.setSelected(true, animated: false)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let colletionViewController = storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController")
            as! CollectionViewController
        
        colletionViewController.pin = view.annotation as! Pin
        
        navigationController!.pushViewController(colletionViewController, animated: true)
    }
}

extension Pin: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude as! Double, longitude: self.longitude as! Double)
        }
        
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}





