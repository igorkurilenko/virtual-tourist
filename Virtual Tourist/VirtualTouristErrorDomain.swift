//
//  VirtualTouristErrorDomain.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/21/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation

let VirtualTouristErrorDomain = "VirtualTouristErrorDomain"

let FlickrRequestError = -1
let AppError = -2

extension NSError {
    
    static func crateAppError(localizedDescription: String, localizedFailureReason: String) -> NSError {
        return createVirtualTouristDomainError(AppError,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason
        )
    }
    
    static func createFlickrRequestError(localizedDescription: String, localizedFailureReason: String) -> NSError {
        return createVirtualTouristDomainError(FlickrRequestError,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason
        )
    }
    
    static func createVirtualTouristDomainError(code: Int, localizedDescription: String, localizedFailureReason: String) -> NSError {
        return createVirtualTouristDomainError(code, userInfo:
            [
                NSLocalizedDescriptionKey: localizedDescription,
                NSLocalizedFailureReasonErrorKey: localizedFailureReason
            ]
        )
    }
    
    static func createVirtualTouristDomainError(code: Int, userInfo: [NSObject:AnyObject]) -> NSError {
        return NSError(domain: VirtualTouristErrorDomain,
            code: code, userInfo: userInfo)
    }
    
}