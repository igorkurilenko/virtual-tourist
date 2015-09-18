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
    private var processEditCollectionState:(() -> Void)!
    private var didSelectItemAtIndexPath: (() -> Void)!
    private var didDeselectItemAtIndexPath: (() -> Void)!
    private var initPhotoCellCheckmarkVisibility: (PhotoCollectionViewCell -> Void)!
    @IBOutlet var editCollectionButton: UIBarButtonItem!
    @IBOutlet var cancelEditCollectionButton: UIBarButtonItem!
    @IBOutlet weak var removeSelectedPhotosButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var editCollectionOnToolbar: UIToolbar!
    @IBOutlet weak var editCollectionOffToolbar: UIToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    private lazy var fetchedPhotosController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false)]
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
        processEditCollectionState()
    }
    
    @IBAction func onNewCollectionButtonTouched(sender: AnyObject) {
    }
    
    @IBAction func onRemoveSelectedPhotosTouched(sender: AnyObject) {
    }
    
    private func editCollectionOn() {
        navigationItem.rightBarButtonItem = cancelEditCollectionButton
        editCollectionOffToolbar.hidden = true
        editCollectionOnToolbar.hidden = false
        processEditCollectionState = editCollectionOff
        collectionView.reloadData()
        didSelectItemAtIndexPath = adjustRemoveSelectedPhotosButtonVisiblity
        didDeselectItemAtIndexPath = adjustRemoveSelectedPhotosButtonVisiblity
        initPhotoCellCheckmarkVisibility = {
            $0.checkmark.hidden = false
        }
    }
    
    private func editCollectionOff() {
        navigationItem.rightBarButtonItem = editCollectionButton
        editCollectionOnToolbar.hidden = true
        editCollectionOffToolbar.hidden = false
        processEditCollectionState = editCollectionOn
        collectionView.reloadData()
        didSelectItemAtIndexPath = {
            // todo: perform segue to image view
        }
        didDeselectItemAtIndexPath = {}
        initPhotoCellCheckmarkVisibility = {
            $0.checkmark.hidden = true
        }
        self.removeSelectedPhotosButton.enabled = false
    }
    
    private func adjustRemoveSelectedPhotosButtonVisiblity() {
        removeSelectedPhotosButton.enabled =
            collectionView.indexPathsForSelectedItems()!.count > 0
    }
    
    private func printError(error: NSError) {
        print(error)
    }
    
    // MARK: - Colleciton View delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        didSelectItemAtIndexPath()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        didDeselectItemAtIndexPath()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedPhotosController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = getReusablePhotoCell("PhotoCollectionViewCell", indexPath: indexPath)
        
        initCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    private func getReusablePhotoCell(reuseId: String, indexPath: NSIndexPath) -> PhotoCollectionViewCell{
        return collectionView.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath)
            as! PhotoCollectionViewCell
    }
    
    private func initCell(cell: PhotoCollectionViewCell, indexPath: NSIndexPath) {
        let photo = fetchedPhotosController.objectAtIndexPath(indexPath) as! Photo
        if let photoFilePath = photo.filePath {
            cell.loadingIndicator.stopAnimating()
            cell.photoImageView.image = UIImage(contentsOfFile: photoFilePath)
        }
        
        initPhotoCellCheckmarkVisibility(cell)
    }
    
    // MARK: - Fetched results controller delegate
    
    var batchUpdates: [()->Void] = []
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        batchUpdates.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            batchUpdates.append {
                self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
            }
            
        case .Update:
            batchUpdates.append {
                self.collectionView.reloadItemsAtIndexPaths([indexPath!])
            }
            
        case .Delete:
            batchUpdates.append {
                self.collectionView.deleteItemsAtIndexPaths([indexPath!])
            }
            
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for update in self.batchUpdates {
                update()
            }
            }, completion: nil)
    }
}