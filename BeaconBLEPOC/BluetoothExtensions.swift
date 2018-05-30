//
//  BluetoothExtensions.swift
//  momenzz
//
//  Created by Stefan Walkner on 06.11.16.
//  Copyright © 2016 Stefan Walkner. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Constants {
    struct Production {
        let name = "momenzz"
        let readCharacteristic = "0003CAA1-0000-1000-8000-00805F9B0131"
        let writeCharacteristic = "0003CBB1-0000-1000-8000-00805F9B0131"
    }

    struct Testing {
        let name = "momenz2"
        let readCharacteristic = "0003CAA1-0000-1000-8000-00805F9B0131"
        let writeCharacteristic = "0003CBB1-0000-1000-8000-00805F9B0131"
    }

    static let environment = Testing()
}

extension CBPeripheral {
    func isMomenzz() -> Bool {
        return name == Constants.environment.name
    }
}

extension CBCharacteristic {
    func isReadCharacteristic() -> Bool {
        return uuid.uuidString == Constants.environment.readCharacteristic
    }

    func isWriteCharacteristic() -> Bool {
        return uuid.uuidString == Constants.environment.writeCharacteristic
    }
}
