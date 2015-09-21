//
//  PhotoPreviewViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/21/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit

class PhotoPreviewViewController: BaseUIViewController {
    var image:UIImage!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
    }
    
}