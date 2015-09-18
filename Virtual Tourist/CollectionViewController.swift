//
//  DetailViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class CollectionViewController: BaseUIViewController, UICollectionViewDelegate,
UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    var pin:Pin!
    private var editCollectionState:(() -> Void)!
    private var updateRemoveSelectedPhotosButtonVisibility: (() -> Void)!
    private var checkmarksHidden = true
    @IBOutlet var editCollectionButton: UIBarButtonItem!
    @IBOutlet var cancelEditCollectionButton: UIBarButtonItem!
    @IBOutlet var removeSelectedPhotosButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var editCollectionOnToolbar: UIToolbar!
    @IBOutlet weak var editCollectionOffToolbar: UIToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    private lazy var fetchedPhotosController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.pin)
        
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
            try fetchedPhotosController.performFetch()
        } catch _ {
        }
        
        initUI()
    }
    
    private func initUI() {
        editCollectionOff()
        adjustCellSize()
        collectionView.allowsMultipleSelection = true
        self.automaticallyAdjustsScrollViewInsets = false;
    }
    
    private func adjustCellSize() {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let size = (view.frame.size.width - 2.0) / 3.0
        
        flowLayout.itemSize = CGSizeMake(size, size)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initMapView()
    }
    
    private func initMapView() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(pin)
        mapView.setRegion(createCoordinateRegion(), animated: false)
    }
    
    private func createCoordinateRegion() -> MKCoordinateRegion {
        let latitude = pin.latitude as Double + 0.0025
        let longitude = pin.longitude as Double
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    @IBAction func onEditCollectionTouched(sender: AnyObject) {
        editCollectionState()
    }
    
    @IBAction func onNewCollectionButtonTouched(sender: AnyObject) {
    }
    
    @IBAction func onRemoveSelectedPhotosTouched(sender: AnyObject) {
    }
    
    private func editCollectionOn() {
        navigationItem.rightBarButtonItem = cancelEditCollectionButton
        editCollectionOffToolbar.hidden = true
        editCollectionOnToolbar.hidden = false
        editCollectionState = editCollectionOff
        checkmarksHidden = false
        collectionView.reloadData()
        updateRemoveSelectedPhotosButtonVisibility = {
            self.removeSelectedPhotosButton.enabled =
                self.collectionView.indexPathsForSelectedItems()!.count > 0
        }
        updateRemoveSelectedPhotosButtonVisibility()
    }
    
    private func editCollectionOff() {
        navigationItem.rightBarButtonItem = editCollectionButton
        editCollectionOnToolbar.hidden = true
        editCollectionOffToolbar.hidden = false
        editCollectionState = editCollectionOn
        checkmarksHidden = true
        collectionView.reloadData()
        updateRemoveSelectedPhotosButtonVisibility = {}
    }
    
    // MARK: - Colleciton View delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        updateRemoveSelectedPhotosButtonVisibility()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        updateRemoveSelectedPhotosButtonVisibility()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedPhotosController.sections![section] 
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath)
            as! PhotoCollectionViewCell
        
        cell.checkmark.hidden = checkmarksHidden
        
        return cell
    }
    
    // MARK: - Fetched results controller delegate
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
    }    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
    }
}