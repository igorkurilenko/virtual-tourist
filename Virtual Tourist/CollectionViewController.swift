//
//  DetailViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/10/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        detailDescriptionLabel.text = "hello world!"
    }

}

