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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate,
UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    @IBOutlet var editCollectionButton: UIBarButtonItem!
    @IBOutlet var doneEditCollectionButton: UIBarButtonItem!
    @IBOutlet weak var removeSelectedPhotosButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var editCollectionOnToolbar: UIToolbar!
    @IBOutlet weak var editCollectionOffToolbar: UIToolbar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var pin:Pin!
    private var processEditCollectionState:(() -> Void)!
    private var didSelectItemAtIndexPath: ((indexPath: NSIndexPath) -> Void)!
    private var didDeselectItemAtIndexPath: (() -> Void)!
    private var updatePhotoCellCheckmarkVisibility: (PhotoAlbumCell -> Void)!
    private lazy var sharedDataContext:NSManagedObjectContext = {
        return Core.instance().coreDataStackManager.managedObjectContext
        }()
    private lazy var remoteDataProvider: RemoteDataProvider = {
        return Core.instance().remoteDataProvider
        }()
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
        
        ensurePhotos()
    }
    
    private func initUI() {
        editCollectionOff()
        adjustCellSize()
        collectionView.allowsMultipleSelection = true
        updateMapView()
        updateActivityIndicatorVisibility()
        updateNoImagesLabelVisibility()
        updateNewCollectionButtonVisibility()
    }
    
    private func adjustCellSize() {
        let flowLayout = collectionView.collectionViewLayout
            as! UICollectionViewFlowLayout
        let size = (view.frame.size.width - 2.0) / 3.0
        
        flowLayout.itemSize = CGSizeMake(size, size)
    }
    
    /// Solves issue If a loading is started but
    /// the app interrupts (e.g. crash) before photos search results recieved.
    private func ensurePhotos() {
        if pin.photosAlbumLoadingState.lastLoadedPage == nil {
            remoteDataProvider.loadPhotos(forPin: pin, context: sharedDataContext)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToPhotosLoadingStateChangeEvent()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromPhotosLoadingStateChangeEvent()
    }
    
    private func updateMapView() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(pin)
        mapView.setRegion(createCoordinateRegion(pin), animated: false)
    }
    
    private func updateNoImagesLabelVisibility() {
        noImagesLabel.hidden = isLoadingInProgress() || hasPhotos()
    }
    
    private func updateNewCollectionButtonVisibility() {
        newCollectionButton.enabled = !isLoadingInProgress()
    }
    
    private func updateActivityIndicatorVisibility() {
        if !isLoadingInProgress() {
            activityIndicator.stopAnimating()
        }
    }
    
    private func updateRemoveSelectedPhotosButtonVisiblity() {
        removeSelectedPhotosButton.enabled = collectionView.hasSelectedItems
    }
    
    // MARK: - Event handlers
    
    @IBAction func onEditCollectionTouched(sender: AnyObject) {
        processEditCollectionState()
    }
    
    @IBAction func onNewCollectionButtonTouched(sender: AnyObject) {
        for photo in fetchedPhotosController.fetchedObjects as! [Photo] {
            remoteDataProvider.cancelImageDownloading(forPin: pin, forPhoto: photo)
            sharedDataContext.deleteObject(photo)
        }
        
        saveCoreDataContext(sharedDataContext)
        
        remoteDataProvider.loadPhotos(forPin: pin, context: sharedDataContext)
        collectionView.reloadData()
    }
    
    @IBAction func onRemoveSelectedPhotosTouched(sender: AnyObject) {
        for indexPath in collectionView.indexPathsForSelectedItems()! {
            let photo = fetchedPhotosController.objectAtIndexPath(indexPath) as! Photo
            remoteDataProvider.cancelImageDownloading(forPin: pin, forPhoto: photo)
            sharedDataContext.deleteObject(photo)
        }
        
        saveCoreDataContext(self.sharedDataContext)
        collectionView.reloadData()
    }
    
    private func onPhotosLoadingStateChanged() {
        updateActivityIndicatorVisibility()
        updateNoImagesLabelVisibility()
        updateNewCollectionButtonVisibility()
    }
    
    // MARK: - Edit collection states
    
    private func editCollectionOn() {
        navigationItem.rightBarButtonItem = doneEditCollectionButton
        editCollectionOffToolbar.hidden = true
        editCollectionOnToolbar.hidden = false
        processEditCollectionState = editCollectionOff
        collectionView.reloadData()
        didSelectItemAtIndexPath = { indexPath in
            self.updateRemoveSelectedPhotosButtonVisiblity()
        }
        didDeselectItemAtIndexPath = updateRemoveSelectedPhotosButtonVisiblity
        updatePhotoCellCheckmarkVisibility = {
            $0.checkmark.hidden = false
        }
    }
    
    private func editCollectionOff() {
        navigationItem.rightBarButtonItem = editCollectionButton
        editCollectionOnToolbar.hidden = true
        editCollectionOffToolbar.hidden = false
        processEditCollectionState = editCollectionOn
        collectionView.reloadData()
        didSelectItemAtIndexPath = { indexPath in
            let photo = self.fetchedPhotosController.objectAtIndexPath(indexPath) as! Photo
            self.previewPhoto(photo)
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        }
        didDeselectItemAtIndexPath = {}
        updatePhotoCellCheckmarkVisibility = {
            $0.checkmark.hidden = true
        }
        self.removeSelectedPhotosButton.enabled = false
    }
    
    private func printError(error: NSError) {
        print(error)
    }
    
    // MARK: - Colleciton View delegate
    
    func collectionView(collectionView: UICollectionView,
        didSelectItemAtIndexPath indexPath: NSIndexPath) {
            didSelectItemAtIndexPath(indexPath: indexPath)
    }
    
    func collectionView(collectionView: UICollectionView,
        didDeselectItemAtIndexPath indexPath: NSIndexPath) {
            didDeselectItemAtIndexPath()
    }
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            let sectionInfo = self.fetchedPhotosController.sections![section]
            
            return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = getReusablePhotoCell("PhotoAlbumCell", indexPath: indexPath)
            
            initCell(cell, indexPath: indexPath)
            
            return cell
    }
    
    private func getReusablePhotoCell(reuseId: String, indexPath: NSIndexPath) -> PhotoAlbumCell{
        return collectionView.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath)
            as! PhotoAlbumCell
    }
    
    private func initCell(cell: PhotoAlbumCell, indexPath: NSIndexPath) {
        let photo = fetchedPhotosController.objectAtIndexPath(indexPath) as! Photo
        if let photoFilePath = photo.filePath {
            cell.loadingIndicator.stopAnimating()
            
            if NSFileManager.defaultManager().fileExistsAtPath(photoFilePath) {
                cell.photoImageView.image = UIImage(contentsOfFile: photoFilePath)
            }
        }
        
        updatePhotoCellCheckmarkVisibility(cell)
    }
    
    // MARK: - Fetched results controller delegate
    
    var batchUpdates: [()->Void] = []
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        batchUpdates.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
            
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
                updateNoImagesLabelVisibility()
                
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

extension PhotoAlbumViewController {
    
    func subscribeToPhotosLoadingStateChangeEvent() {
        pin.photosAlbumLoadingState.addObserver(
            self, forKeyPath: "inProgress",
            options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    func unsubscribeFromPhotosLoadingStateChangeEvent() {
        pin.photosAlbumLoadingState.removeObserver(
            self, forKeyPath: "inProgress")
    }
    
    override func observeValueForKeyPath(keyPath: String?,
        ofObject object: AnyObject?, change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            guard keyPath != nil else {
                super.observeValueForKeyPath(
                    keyPath, ofObject: object, change: change, context: context)
                return
            }
            
            switch keyPath! {
            case "inProgress":
                onPhotosLoadingStateChanged()
                
            default:
                return
            }
    }
}

extension UICollectionView {
    
    var hasSelectedItems:Bool {
        if let paths = indexPathsForSelectedItems() {
            return !paths.isEmpty
        
        } else {
            return false
        }
    }
    
}

extension PhotoAlbumViewController {
    private func previewPhoto(photo:Photo) {
        if let filePath = photo.filePath {
            if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                let photoPreviewViewController = self.getPhotoPreviewViewController()
                photoPreviewViewController.image = UIImage(contentsOfFile: filePath)
                
                self.navigationController!.pushViewController(photoPreviewViewController, animated: true)
            }
        }
    }
    
    private func getPhotoPreviewViewController() -> PhotoPreviewViewController {
            return storyboard!.instantiateViewControllerWithIdentifier("PhotoPreviewViewController")
                as! PhotoPreviewViewController
    }
    
    private func hasPhotos() -> Bool {
        return !pin.photos.isEmpty
    }
    
    private func isLoadingInProgress() -> Bool{
        return pin.photosAlbumLoadingState.inProgress.boolValue
    }
    
    private func createCoordinateRegion(pin: Pin) -> MKCoordinateRegion {
        let latitude = pin.latitude as Double + 0.0025
        let longitude = pin.longitude as Double
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return MKCoordinateRegion(center: center, span: span)
    }
}