//
//  File.swift
//  
//
//  Created by Sarosh Tahir on 12/01/2023.
//

import Foundation
import CoreBluetooth

struct CBUUIDs {
    static let BLEService_UUID = CBUUID(string: "87b1de8d-e7cb-4ea8-a8e4-290209522c83")
    static let BLEChar_UUID = CBUUID(string: "e68a5c09-aef8-4447-8f10-f3339898dee9")
    static let BLENotifyChar_UUID = CBUUID(string: "540810c2-d573-11e5-ab30-625662870761")
    static let BLEWriteChar_UUID = CBUUID(string: "54080bd6-d573-11e5-ab30-625662870761")
}
