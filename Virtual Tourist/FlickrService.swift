//
//  FlickrService.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/16/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation
import MapKit

// todo: refactor this service
class FlickrService {
    typealias OnError = (NSError) -> Void
    typealias SearchPhotosOnSuccess = ([String:AnyObject]?) -> Void
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "97d099ba55b39bd64c914b116d2f1124"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    
    var urlSession:NSURLSession
    
    init(urlSession: NSURLSession) {
        self.urlSession = urlSession
    }
    
    func searchPhotos(
        coordinate: CLLocationCoordinate2D,
        withPage page: Int = 1,
        withPerPage perPage: Int = 24,
        onError: OnError,
        onSuccess: SearchPhotosOnSuccess) {
            
            let queryParams = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": createBoundingBoxString(coordinate),
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK,
                "page": "\(page)",
                "per_page": "\(perPage)"
            ]
            
            let httpGet = HttpRequest.createGet(BASE_URL, queryParams: queryParams)!
            
            urlSession.dataTaskWithRequest(httpGet) {data, response, downloadError in
                if let error = downloadError {
                    println("Could not complete the request \(error)")
                } else {
                    
                    var parsingError: NSError? = nil
                    let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! [String:AnyObject]
                    
                    onSuccess(parsedResult)
                }
            }.resume()
    }
    
    private func createBoundingBoxString(coordinate: CLLocationCoordinate2D) -> String {
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}