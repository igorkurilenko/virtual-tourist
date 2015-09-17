//
//  SelectableCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/16/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit

class SelectableCollectionViewCell: UICollectionViewCell {
    private let checkmarkTextSign = "✓"
    
    var checkmark: UITextField! {
        didSet {
            checkmark.layer.borderColor = UIColor.whiteColor().CGColor
            checkmark.layer.borderWidth = 1.0
            checkmark.layer.cornerRadius = 15
            checkmark.clipsToBounds = true
            checkmark.enabled = false
            checkmark.text = ""
        }
    }
    
    
    override var selected: Bool {
        didSet {
            if selected {
                renderSelected()
            } else {
                renderDeselected()
            }
        }
    }
    
    private func renderSelected() {
        checkmark.layer.backgroundColor = checkmark.tintColor.CGColor
        checkmark.text = checkmarkTextSign
        
    }
    
    private func renderDeselected() {
        checkmark.layer.backgroundColor = UIColor.clearColor().CGColor
        checkmark.text = ""
    }
    
}