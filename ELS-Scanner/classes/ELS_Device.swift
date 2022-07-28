//
//  ELS_Device.swift
//  ELS-Scanner
//
//  Created by Voltensee iMac on 30.10.20.
//  Copyright © 2020 Voltensee GmbH. All rights reserved.
//

import Foundation

struct ELS_Device: Codable {
    var ELS_Name: String
    var ELS_UserName: String
    var ELS_State: Bool
    var ELS_LastScanTime: Int
    var ELS_MAC: String
    var ELS_RSSI: Int?
    var ELS_IsBlocked: Bool
}
