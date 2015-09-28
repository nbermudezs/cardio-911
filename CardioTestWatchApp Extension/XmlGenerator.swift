//
//  XmlGenerator.swift
//  CardioTest
//
//  Created by Nestor Bermudez Sarmiento on 9/26/15.
//  Copyright © 2015 Nestor Bermudez. All rights reserved.
//

import WatchKit

class XmlGenerator: NSObject {
    func fromDictionary(dictionary: [String:String]) -> String {
        let wrapFormat = "<?xml version=\"%@\"encoding=\"%@\"?>%@"
        return String(format: wrapFormat, "1.0", "UTF-8", recursiveEncode(dictionary))
    }

    private func recursiveEncode(data: [String:String]) -> String {
        var locals = ""
        for (key, value) in data {
            locals += String(format: "<%@>%@</%@>", key, value, key)
        }
        return locals
    }
}
