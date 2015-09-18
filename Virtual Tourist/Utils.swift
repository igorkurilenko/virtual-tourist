//
//  Utils.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/17/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation

typealias OnError = (NSError) -> Void

func ifErrorElse(error: NSError?, errorHandler: OnError, noErrorHandler: () -> Void) {
    if let error = error {
        errorHandler(error)
        
    } else {
        noErrorHandler()
    }
}