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
    @IBOutlet var editPinsButton: UIBarButtonItem!
    @IBOutlet var doneEditPinsButton: UIBarButtonItem!
    private var lastPin:Pin!
    private var processEditPinsState:(() -> Void)!
    private var handleLongPress:((UIGestureRecognizer) -> Void)!
    private var didSelectAnnotationView: ((MKAnnotationView) -> Void)!
    private let mapRegionService = WithCurrentLocationDetectionIfNotExists(
        decoratee: MapRegionArchiverService())
    private lazy var sharedDataContext: NSManagedObjectContext = {
        return Core.instance().coreDataStackManager.managedObjectContext
        }()
    private lazy var remoteDataProvider: RemoteDataProvider = {
        return Core.instance().remoteDataProvider
        }()
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
        
        initUI()
    }
    
    private func initUI() {
        editPinsOff()
        initGestureRecognizer()
        initMapRegion()
        mapView.addAnnotations(fetchedPinsController.fetchedObjects as! [Pin])
    }
    
    private func initGestureRecognizer() {
        let longPressGestureRecognizer =
        UILongPressGestureRecognizer(target: self, action: "onLongPress:")
        
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func initMapRegion() {
        mapRegionService.getMapRegion { mapRegion in
            if let mapRegion = mapRegion {
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView.setRegion(mapRegion, animated: true)
                }
            }
        }
    }
    
    // MARK: - Event handlers
    
    func onLongPress(gestureRecognizer: UIGestureRecognizer) {
        handleLongPress(gestureRecognizer)
    }
    
    @IBAction func onEditPinsTouched(sender: AnyObject) {
        processEditPinsState()
    }
    
    // MARK: - Edit map view pins states
    
    private func editPinsOn() {
        navigationItem.rightBarButtonItem = doneEditPinsButton
        processEditPinsState = editPinsOff
        
        didSelectAnnotationView = { view in
            self.destructiveConfirm("Remove"){ action in
                let pin = view.annotation as! Pin
                
                self.removePin(pin)
                
                saveCoreDataContext(self.sharedDataContext)
            }
        }
        
        handleLongPress = { gestureRecognizer in
        }
    }
    
    private func editPinsOff() {
        navigationItem.rightBarButtonItem = editPinsButton
        processEditPinsState = editPinsOn
        
        didSelectAnnotationView = { view in
            let colletionViewController = self.getPhotoAlbumViewController()
            colletionViewController.pin = view.annotation as! Pin
            
            self.navigationController!.pushViewController(colletionViewController, animated: true)
            // In case if user goes back from album view and then wants to open album again:
            // if pin is selected it's impossible to open album again.
            self.mapView.deselectAnnotation(view.annotation, animated: false)
        }
        
        handleLongPress = { gestureRecognizer in
            switch gestureRecognizer.state {
            case .Began:
                let coordinate = self.getGestureCoordinate(gestureRecognizer)
                self.addPin(coordinate)
                
            case .Changed:
                let coordinate = self.getGestureCoordinate(gestureRecognizer)
                self.lastPin.coordinate = coordinate
                
            case .Ended:
                saveCoreDataContext(self.sharedDataContext)
                self.remoteDataProvider.loadPhotos(
                    forPin: self.lastPin,
                    context: self.sharedDataContext,
                    onError: self.onError)
                
            default:
                return
            }
        }
    }
    
    // MARK: - Map view delegate
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegionService.persistMapRegion(mapView.region)
    }
    
    func mapView(mapView: MKMapView,
        viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
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
        didSelectAnnotationView(view)
    }
    
}

extension Pin: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(
                latitude: self.latitude as Double,
                longitude: self.longitude as Double)
        }
        
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}

extension MapViewController {
    private func onError(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            let message = Message.create(error)
            
            self.displayErrorMessage(message)
        }
    }
    
    private func removePin(pin: Pin) {
        remoteDataProvider.cancelLoading(forPin: pin)
        sharedDataContext.deleteObject(pin)
        mapView.removeAnnotation(pin)
    }
    
    private func destructiveConfirm(title: String, handler: (UIAlertAction) -> Void) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let alertAction = UIAlertAction(title: title, style: UIAlertActionStyle.Destructive, handler: handler)
        
        alertController.addAction(alertAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func getGestureCoordinate(gestureRecognizer: UIGestureRecognizer) -> CLLocationCoordinate2D {
        let pressPoint = gestureRecognizer.locationInView(mapView)
        
        return mapView.convertPoint(pressPoint, toCoordinateFromView: mapView)
    }
    
    private func addPin(coordinate: CLLocationCoordinate2D) {
        lastPin = Pin(coordinate: coordinate, context: sharedDataContext)
        
        mapView.addAnnotation(lastPin)
    }
    
    private func getPhotoAlbumViewController() -> PhotoAlbumViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")
            as! PhotoAlbumViewController
    }
}



