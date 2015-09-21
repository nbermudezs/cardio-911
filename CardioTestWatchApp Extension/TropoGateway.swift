//
//  TropoGateway.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/13/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

protocol TropoGatewayDelegate : class {
    func callDidSucceed()
}

class TropoGateway {
    let voiceApiKey = "0e8d238f7cde9c4e86d1afddc3375e3d5b301c6bca85517a50fe7752343b130c3a9464a75ece5b208bca5fe4"
    let smsApiKey = "0e8d2aceb21cb94b8002f71c86b3e5afa3523aef717cd9a9363cbe9b8eb744e469930c81c50ed70d47e69625"
    let host = "https://api.tropo.com"
    let apiVersion = "1.0"
    let restApiManager = RestApiManager()
    
    weak var delegate: TropoGatewayDelegate?
    
    init() {
        
    }
    
    func notifyUserInTroubles(number: String, name: String) {
        let url = String(format: "%@/%@/sessions?action=create&token=%@&number=%@", host, apiVersion, voiceApiKey, number)
        restApiManager.makeHTTPGetRequest(url) { (data, error) -> Void in
            if error == nil {
                self.delegate?.callDidSucceed()
            }
        }
    }
}