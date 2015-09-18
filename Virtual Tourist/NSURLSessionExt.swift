//
//  NSURLSessionExt.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/16/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit

extension NSURLSession {
    typealias OnError = (NSError) -> Void
    typealias OnSuccess = (UIImage?) -> Void
    
    func downloadImage(url: NSURL, onError: OnError, onSuccess: OnSuccess) {
        dataTaskWithURL(url) { data, response, error in
            ifErrorElse(error, errorHandler: onError){
                onSuccess(UIImage(data: data!))
            }
            }.resume()
    }
}