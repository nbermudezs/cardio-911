//
//  RestApiManager.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/20/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

typealias Dict = [String: AnyObject]?
typealias ServiceResponse = (Dict, NSError?) -> Void

enum RestApiManagerError: ErrorType {
    case Serialization
}

enum ResponseType {
    case JSON
    case XML
}

protocol ResponseHandler: class {
    func handle(data: NSData?) throws -> [String: AnyObject]?
}

class JsonResponseHandler: ResponseHandler {
    func handle(data: NSData?) throws -> [String: AnyObject]? {
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
        if let dict = jsonObject as? [String: AnyObject] {
            return dict
        }
        return nil
    }
}

class XmlResponseHandler: ResponseHandler {
    func handle(data: NSData?) throws -> [String: AnyObject]? {
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
        if let dict = jsonObject as? [String: AnyObject] {
            return dict
        }
        return nil
    }
}

class RestApiManager: NSObject {
    let responseType: ResponseType
    let responseHandler: ResponseHandler

    init(responseType: ResponseType) {
        self.responseType = responseType
        switch responseType {
        case .JSON:
            self.responseHandler = JsonResponseHandler()
        case .XML:
            self.responseHandler = XmlResponseHandler()
        }
    }

    func makeHTTPPostRequest(path: String, body: [String: AnyObject], headers: [String:String], onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        let params : AnyObject? = body["params"]

        // Set the method to POST
        request.HTTPMethod = "POST"
        self.setHeaders(request, headers: headers)

        // Set the POST body for the request
        if params != nil && false {
            let httpBody = try? NSJSONSerialization.dataWithJSONObject(params!, options: .PrettyPrinted)
            request.HTTPBody = httpBody
            request.HTTPBody = String(format: "From=%@&To=%@&Body=%@", "%2B13122011010", "%2B19704995058", "potato").dataUsingEncoding(NSASCIIStringEncoding)
        }

        self.makeRequest(request, basicAuth: nil, onCompletion: onCompletion)
        return true
    }

    func makeHTTPGetRequest(path: String, onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)

        request.HTTPMethod = "GET"
        self.setHeaders(request, headers: [:])

        self.makeRequest(request, basicAuth: nil, onCompletion: onCompletion)
        return true
    }


    func makeRequest(request: NSMutableURLRequest, basicAuth: [String: String]?, onCompletion: ServiceResponse) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        if basicAuth != nil {
            config.HTTPAdditionalHeaders = basicAuth!
        }
        let session = NSURLSession(configuration: config)

        print(request.URL)
        // print(NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding))
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let headers = response as? NSHTTPURLResponse {
                let statusCode = headers.statusCode
                let parsed = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print(parsed)
                if statusCode == 200 {
                    if let responseDictionary = try? self.responseHandler.handle(data) {
                        onCompletion(responseDictionary, nil)
                    } else {
                        onCompletion(nil, nil)
                    }
                } else {
                    onCompletion(nil, NSError(domain: "MakeRequestResponseError", code: statusCode, userInfo: nil))
                }
            } else {
                onCompletion(nil, NSError(domain: "EmptyResponse", code: 500, userInfo: nil))
            }
        })
        task.resume()
    }

    private func setHeaders(request: NSMutableURLRequest, headers: [String:String]) {
        if responseType == .JSON {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        } else if responseType == .XML {
            //request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        }
    }
}