//
//  DetailViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import UIKit
import MapKit

class CollectionViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var pin:Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        let latitude = pin.latitude as! Double + 0.003
        let longitude = pin.longitude as! Double
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
}

