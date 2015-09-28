//
//  TropoGateway.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/13/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

class TropoGateway: Gateway {
    let voiceApiKey = "0e8d238f7cde9c4e86d1afddc3375e3d5b301c6bca85517a50fe7752343b130c3a9464a75ece5b208bca5fe4"
    let smsApiKey = "0e8d2aceb21cb94b8002f71c86b3e5afa3523aef717cd9a9363cbe9b8eb744e469930c81c50ed70d47e69625"
    let host = "https://api.tropo.com"
    let apiVersion = "1.0"
    let restApiManager = RestApiManager(responseType: .XML)

    var voiceAuthUrl: String = ""
    
    override init() {
        voiceAuthUrl = String(format: "%@/%@/sessions?action=create&token=%@", host, apiVersion, voiceApiKey)
    }

    override func sendSmsNotification(from: String, to: String, body: String) {
    }

    override func sendTtsSms(from: String, to: String, body: String) {

    }

    override func sendVoiceCall(from: String, to: String, data: [String : String]) {
        var initial = ["from": from, "to": to]
        initial.merge(data)
        let fromData = String.queryStringFromParameters(initial)
        let url = String(format: "%@&%@", voiceAuthUrl, fromData!)

        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"

        self.makeRequest(request) { dict, error in
            if error == nil {
                self.delegate?.callDidSucceed()
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
                    if let responseDictionary = try? self.handleXmlResponse(data) {
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

    private func handleXmlResponse(data: NSData?) throws -> [String: AnyObject]? {
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
        if let dict = jsonObject as? [String: AnyObject] {
            return dict
        }
        return nil
    }
}