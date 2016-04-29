//
//  RestcommGateway.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/13/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

class RestCommGateway: Gateway {
    let accountSid = "ACae6e420f425248d6a26948c17a9e2acf"
    let authToken = "70fdde318b899c9822045c4ae54eadce"
    let baseUrl = "http://23.23.228.238:8080/restcomm"
    let version = "2012-04-24"

    let restApiManager = RestApiManager(responseType: .XML)

    var restCommApiCommon = ""

    override init() {
        restCommApiCommon = String(format: "%@/%@/Accounts/%@", baseUrl, version, accountSid)
    }

    override func sendSmsNotification(from: String, to: String, body: String) {
        let url = String(format: "%@/SMS/Messages?From=%@", restCommApiCommon, from)
        let loginString = NSString(format: "%@:%@", accountSid, authToken)
        let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
        let base64LoginString = loginData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)

        let headers = ["Authorization": String(format: "Basic %@", base64LoginString)]
        restApiManager.makeHTTPPostRequest(url, body: ["params": ["To": to, "From": from, "Body": body]], headers: headers) { (data, error) -> Void in
            if error == nil {
                self.delegate?.smsWasSent()
            }
        }
    }

    func sendVoiceNotification(from: String, to: String, body: String) {
        //let resourceUrl = "http://23.23.228.238:8080/restcomm-rvd/services/apps/TADHack-2015/start".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        // let url = String(format: "%@/Calls?From=%@&To=%@&Url=%@", restCommApiCommon, from, to, resourceUrl!)
        let url = "http://23.23.228.238:8080/restcomm-rvd/services/apps/TADHack-2015/start?to=14349965226"

        let userPasswordString = "ACae6e420f425248d6a26948c17a9e2acf:961c09ae42e6d74e99e5745e39d161af"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue:0))
        let authString = "Basic \(base64EncodedCredential)"

        let headers = ["Authorization": authString]

        let request = NSMutableURLRequest(URL: NSURL(string: url)!)

        request.HTTPMethod = "GET"

        restApiManager.makeRequest(request, basicAuth: headers) { (data, error) -> Void in
            if error == nil {
                //self.delegate?.smsWasSent()
            }
        }
    }

    private func handle(data: NSData?) throws -> [String: AnyObject]? {
        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
        if let dict = jsonObject as? [String: AnyObject] {
            return dict
        }
        return nil
    }

    override func sendTtsSms(from: String, to: String, body: String) {

    }
}