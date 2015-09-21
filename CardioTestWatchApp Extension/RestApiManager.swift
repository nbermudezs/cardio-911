//
//  RestApiManager.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/20/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation


typealias ServiceResponse = ([String: AnyObject]?, NSError?) -> Void

enum RestApiManagerError: ErrorType {
    case Serialization
}

class RestApiManager: NSObject {
    func makeHTTPPostRequest(path: String, body: [String: AnyObject], onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        let params : AnyObject? = body["params"]

        // Set the method to POST
        request.HTTPMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Set the POST body for the request
        if params != nil {
            do {
                try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params!, options: .PrettyPrinted)
            } catch {
                print("Something failed while serializing params")
                return false
            }
        }

        self.makeRequest(request, onCompletion: onCompletion)
        return true
    }

    func makeHTTPGetRequest(path: String, onCompletion: ServiceResponse) -> Bool {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)

        request.HTTPMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        self.makeRequest(request, onCompletion: onCompletion)
        return true
    }

    private func makeRequest(request: NSMutableURLRequest, onCompletion: ServiceResponse) {
        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            let headers = response as? NSHTTPURLResponse
            let statusCode = headers!.statusCode
            if statusCode == 200 {
                onCompletion(nil, nil)
            } else {
                onCompletion(nil, NSError(domain: "MakeRequestResponseError", code: statusCode, userInfo: nil))
            }
        })
        task.resume()
    }

    private func handleJsonResponse(data: NSData?) throws -> [String: AnyObject]? {
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
        if let dict = jsonObject as? [String: AnyObject] {
            return dict
        }
        return nil
    }
}