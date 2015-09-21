//
//  FlickrService.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/16/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import MapKit

protocol FlickrClient {
    
    func searchPhotos(
        coordinate: CLLocationCoordinate2D,
        page: Int,
        onError: OnError,
        onSuccess: NSDictionary -> Void) -> NSURLSessionDataTask
}

// todo: refactor this service
class DefaultFlickrClient: FlickrClient {
    
    struct SearchPhotosConfig {
        static let BaseUrl = "https://api.flickr.com/services/rest/"
        static let MethodName = "flickr.photos.search"
        static let ApiKey = "97d099ba55b39bd64c914b116d2f1124"
        static let Extras = "url_m"
        static let SafeSearch = "1"
        static let DataFormat = "json"
        static let NoJsonCallback = "1"
        static let BoundingBoxHalfWidth = 0.0025
        static let BoundingBoxHalfHeight = 0.0025
        static let LatMin = -90.0
        static let LatMax = 90.0
        static let LonMin = -180.0
        static let LonMax = 180.0
        static let RequestTimeoutSeconds:NSTimeInterval = 60
        static let PerPage = 21
    }
    
    var urlSession:NSURLSession
    
    init(urlSession: NSURLSession) {
        self.urlSession = urlSession
    }
    
    func searchPhotos(coordinate: CLLocationCoordinate2D, page: Int,
        onError: OnError, onSuccess: NSDictionary -> Void) -> NSURLSessionDataTask {
            let request = createSearchPhotoRequest(coordinate, page: page)
            
            let task = urlSession.dataTaskWithRequest(request) {data, response, downloadError in
                ifErrorElse(downloadError, errorHandler: onError) {
                    do{
                        let parsedResult = (try NSJSONSerialization.JSONObjectWithData(data!,
                            options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
                        
                        onSuccess(parsedResult)

                    } catch {
                        onError(error as NSError)
                    }
                }
            }
            
            task.resume()
            
            return task
    }
    
    private func createSearchPhotoRequest(coordinate: CLLocationCoordinate2D, page: Int) -> NSURLRequest {
        let queryParams = [
            "method": SearchPhotosConfig.MethodName,
            "api_key": SearchPhotosConfig.ApiKey,
            "bbox": createBoundingBoxString(coordinate),
            "safe_search": SearchPhotosConfig.SafeSearch,
            "extras": SearchPhotosConfig.Extras,
            "format": SearchPhotosConfig.DataFormat,
            "nojsoncallback": SearchPhotosConfig.NoJsonCallback,
            "page": "\(page)",
            "per_page": "\(SearchPhotosConfig.PerPage)"
        ]
        
        let httpGet = HttpRequest.createGet(SearchPhotosConfig.BaseUrl, queryParams: queryParams)!
        httpGet.timeoutInterval = SearchPhotosConfig.RequestTimeoutSeconds
        
        return httpGet
    }        
    
    private func createBoundingBoxString(coordinate: CLLocationCoordinate2D) -> String {
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - SearchPhotosConfig.BoundingBoxHalfWidth, SearchPhotosConfig.LonMin)
        let top_right_lon = min(longitude + SearchPhotosConfig.BoundingBoxHalfWidth, SearchPhotosConfig.LonMax)
        let bottom_left_lat = max(latitude - SearchPhotosConfig.BoundingBoxHalfHeight, SearchPhotosConfig.LatMin)
        let top_right_lat = min(latitude + SearchPhotosConfig.BoundingBoxHalfHeight, SearchPhotosConfig.LatMax)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}