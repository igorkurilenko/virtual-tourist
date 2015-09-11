//
//  MasterViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import UIKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate {

    lazy var sharedDataContext: NSManagedObjectContext = {
       return CoreDataStackManager.instance().managedObjectContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}

