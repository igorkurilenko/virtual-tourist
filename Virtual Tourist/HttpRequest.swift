//
//  HttpRequest.swift
//  On the Map
//
//  Created by kurilenko igor on 7/15/15.
//  Copyright (c) 2015 igor kurilenko. All rights reserved.
//

import Foundation

class HttpRequest:NSMutableURLRequest {
    private convenience init?(url: String) {
        self.init(url: url, queryParams: [:])
    }
    
    private convenience init?(var url: String, queryParams: [String:AnyObject]) {
        assert(url.rangeOfString("?") == nil, "Url string already contains query parameters")
        
        url += HttpRequest.buildQueryString(queryParams)
        
        self.init(URL: NSURL(string: url)!)
    }
    
    func setHeader(name: String, value: String) {
        setValue(value, forHTTPHeaderField: name)
    }
    
    static func createGet(url: String) -> HttpGet? {
        return HttpGet(url: url)
    }
    
    static func createGet(url: String, queryParams: [String:AnyObject]) -> HttpGet? {
        return HttpGet(url: url, queryParams: queryParams)
    }
        
    class func buildQueryString(queryParams: [String:AnyObject]) -> String {
        var urlVars = [String]()
        
        for (key, value) in queryParams {
            let stringValue = "\(value)"
            let escapedValue = escape(stringValue)
            urlVars += [key + "=" + "\(escapedValue)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func escape(value: String) -> String{
        return value.stringByAddingPercentEncodingWithAllowedCharacters(
            NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
}

class HttpGet: HttpRequest { }