//
//  AppDelegate.swift
//  BeaconBLEPOC
//
//  Created by Stefan Walkner on 14.09.16.
//  Copyright © 2016 Stefan Walkner. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    private var centralManager:CBCentralManager!
    private var sensorTag:CBPeripheral?
    private let timerPauseInterval:NSTimeInterval = 10.0
    private let timerScanInterval:NSTimeInterval = 2.0
    private let sensorTagName = "SensorTagName"
    private let locationManager = CLLocationManager()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        startBeaconMonitoring()
        return true
    }
    
    private func startBeaconMonitoring() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            if CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }

    func startScanning() {
        let uuid = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "ESTIMOTE")
        locationManager.startMonitoringForRegion(beaconRegion)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
        LocalNotifications.sendLocalNotification("66", shouldRepeat: false)
    }
    
    func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        print(error)
        LocalNotifications.sendLocalNotification("71", shouldRepeat: false)
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        LocalNotifications.sendLocalNotification("enter", shouldRepeat: false)
        setupBLE()
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        LocalNotifications.sendLocalNotification("exit ", shouldRepeat: false)
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print(error)
        LocalNotifications.sendLocalNotification("85", shouldRepeat: false)
    }
}

extension AppDelegate: CBCentralManagerDelegate, CBPeripheralDelegate {
    private func setupBLE() {
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), options: [CBCentralManagerOptionRestoreIdentifierKey:"myCentralManagerIdentifier"])
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        LocalNotifications.sendLocalNotification("\(dict)", shouldRepeat: false)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        LocalNotifications.sendLocalNotification("100", shouldRepeat: false)
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, forService: service)
        }
        LocalNotifications.sendLocalNotification("108", shouldRepeat: false)
        print(peripheral.services)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        LocalNotifications.sendLocalNotification("123", shouldRepeat: false)
        print(characteristic)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var message = ""
        
        switch central.state {
        case .PoweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .Unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .Unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .Resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .Unknown:
            message = "The state of the BLE Manager is unknown."
        case .PoweredOn:
            message = "Bluetooth LE is turned on and ready for communication."
            
            let sensorTagAdvertisingUUID3 = CBUUID(string: "0003cab5-0000-1000-8000-00805f9b0131")
            centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID3], options: nil)
            LocalNotifications.sendLocalNotification("PoweredOn \(sensorTagAdvertisingUUID3)", shouldRepeat: false)
        }
        
        print(message)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(advertisementData[CBAdvertisementDataLocalNameKey])\" \(peripheral.name) - \(advertisementData)")
        LocalNotifications.sendLocalNotification("found something", shouldRepeat: false)
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.UUIDString)")
            
            if peripheralName == sensorTagName {
                LocalNotifications.sendLocalNotification("**** SENSOR TAG FOUND! ADDING NOW!!!", shouldRepeat: false)
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connectPeripheral(sensorTag!, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        LocalNotifications.sendLocalNotification("\(error)", shouldRepeat: false)
    }

    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        LocalNotifications.sendLocalNotification("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!", shouldRepeat: false)
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
}
