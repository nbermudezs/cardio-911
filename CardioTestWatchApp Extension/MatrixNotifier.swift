//
//  MatrixNotifier.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 10/3/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

class MatrixNotifier {
    let baseUrl = "https://matrix.org/_matrix/client/api/v1"
    let adminToken = "QGFkbWluLWNhcmRpbzkxMTptYXRyaXgub3Jn.IInBbqfIoIWUQzSuXg"
    let adminRoom = "!ZdOQsfbvckGomQXPRN:matrix.org"

    let userToken = "QG5iZXJtdWRlenM6bWF0cml4Lm9yZw...NpwLQJLbpbbbTdXlAM"
    let userRoom = "!CCqGnakGHbhaqdDETR:matrix.org"

    init() {

    }

    func notifyAdminChannel(to: String, name: String, location: String) {
        let url = String(format: "%@/rooms/%@/send/m.room.message?access_token=%@", baseUrl, adminRoom, adminToken)
        print(url)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let bodyStr = String(format: "{\"msgtype\": \"heart\", \"to\": \"%@\", \"name\": \"%@\", \"location\": \"%@\"}", to, name, location)
        let params : [String: String] = ["msgtype": "m.text", "body": bodyStr]

        self.sendMessage(request, params: params)
    }

    func notifyContact(name: String, location: String) {
        let url = String(format: "%@/rooms/%@/send/m.room.message?access_token=%@", baseUrl, userRoom, userToken)
        print(url)
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let bodyStr = String(format: "This is %@. I'm having a heart attack. Please send help. This is my location %@", name, location)
        let params : [String: String] = ["msgtype": "m.text", "body": bodyStr]

        self.sendMessage(request, params: params)
    }

    private func sendMessage(request: NSMutableURLRequest, params: [String:String]) {
        // Set the method to POST
        request.HTTPMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        // Set the POST body for the request
        let httpBody = try? NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
        request.HTTPBody = httpBody

        self.makeRequest(request) { success, error in
            if error != nil {
                print("Awesome!")
            } else {
                print(error)
            }
        }
    }

    private func makeRequest(request: NSMutableURLRequest, onCompletion: ServiceResponse) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)

        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let headers = response as? NSHTTPURLResponse {
                let statusCode = headers.statusCode
                let parsed = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print(parsed)
                if statusCode == 200 {
                    onCompletion(nil, nil)
                } else {
                    onCompletion(nil, NSError(domain: "MakeRequestResponseError", code: statusCode, userInfo: nil))
                }
            } else {
                onCompletion(nil, NSError(domain: "EmptyResponse", code: 500, userInfo: nil))
            }
        })
        task.resume()
    }
}