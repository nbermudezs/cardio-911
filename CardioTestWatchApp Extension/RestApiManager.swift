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

    func makeHTTPPostRequest(path: String, body: [String: AnyObject], onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        let params : AnyObject? = body["params"]

        // Set the method to POST
        request.HTTPMethod = "POST"
        self.setHeaders(request)

        // Set the POST body for the request
        if params != nil {
            let httpBody = try? NSJSONSerialization.dataWithJSONObject(params!, options: .PrettyPrinted)
            request.HTTPBody = httpBody
        }

        self.makeRequest(request, onCompletion: onCompletion)
        return true
    }

    func makeHTTPGetRequest(path: String, onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)

        request.HTTPMethod = "GET"
        self.setHeaders(request)

        self.makeRequest(request, onCompletion: onCompletion)
        return true
    }

    private func makeRequest(request: NSMutableURLRequest, onCompletion: ServiceResponse) {
        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let headers = response as? NSHTTPURLResponse {
                let statusCode = headers.statusCode
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

    private func setHeaders(request: NSMutableURLRequest) {
        if responseType == .JSON {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
    }
}