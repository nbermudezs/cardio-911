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
    let authToken = "961c09ae42e6d74e99e5745e39d161af"
    let baseUrl = "http://54.74.109.130:8080/restcomm"
    let version = "2012-04-24"

    let restApiManager = RestApiManager(responseType: .XML)

    var restCommApiCommon = ""

    override init() {
        restCommApiCommon = String(format: "%@/%@/Accounts/%@", baseUrl, version, accountSid)
    }

    override func sendSmsNotification(from: String, to: String, body: String) {
        let url = String(format: "%@/SMS/Messages", restCommApiCommon)
        restApiManager.makeHTTPPostRequest(url, body: ["params": ["to": to, "from": from, "body": body]]) { (data, error) -> Void in
            if error == nil {
                self.delegate?.smsWasSent()
            }
        }
    }

    override func sendTtsSms(from: String, to: String, body: String) {

    }
}