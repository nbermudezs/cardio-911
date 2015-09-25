//
//  GatewayProtocols.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/22/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import Foundation

protocol GatewayProtocol: class {
    func sendSmsNotification(from: String, to: String, body: String)
    func sendTtsSms(from: String, to: String, body: String)
}

protocol GatewayDelegate: class {
    func smsWasSent()
    func callDidSucceed()
}

class Gateway: GatewayProtocol {
    weak var delegate: GatewayDelegate?

    func sendTtsSms(from: String, to: String, body: String) {
    }

    func sendSmsNotification(from: String, to: String, body: String) {
    }
}