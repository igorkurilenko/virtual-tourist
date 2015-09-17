//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/16/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit

class PhotoCollectionViewCell: SelectableCollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var checkmarkOutlet: UITextField! {
        didSet {
            checkmark = checkmarkOutlet
        }
    }
    
    override var selected: Bool {
        didSet {
            photoImageView.alpha = selected ? 0.8 : 1.0
        }
    }
}