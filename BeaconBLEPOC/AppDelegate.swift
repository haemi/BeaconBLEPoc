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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    fileprivate var centralManager:CBCentralManager!
    fileprivate var sensorTag:CBPeripheral?
    fileprivate let timerPauseInterval:TimeInterval = 10.0
    fileprivate let timerScanInterval:TimeInterval = 2.0
    fileprivate let sensorTagName = "momenz2"
    fileprivate let locationManager = CLLocationManager()
    
    fileprivate var peripheral: CBPeripheral?
    fileprivate var isGrantedNotificationAccess = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            self.isGrantedNotificationAccess = granted
        }
        
        startBeaconMonitoring()
        // setupBLE()
        return true
    }
    
    fileprivate func startBeaconMonitoring() {
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "ESTIMOTE")
        locationManager.startMonitoring(for: beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        LocalNotifications.sendLocalNotification("66", shouldRepeat: false)
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error)
        LocalNotifications.sendLocalNotification("71", shouldRepeat: false)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        LocalNotifications.sendLocalNotification("enter", shouldRepeat: false)
        setupBLE()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        LocalNotifications.sendLocalNotification("exit ", shouldRepeat: false)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(error)
        LocalNotifications.sendLocalNotification("85", shouldRepeat: false)
    }
}

extension AppDelegate: CBCentralManagerDelegate, CBPeripheralDelegate {
    fileprivate func setupBLE() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .default), options: [CBCentralManagerOptionRestoreIdentifierKey:"myCentralManagerIdentifier"])
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        LocalNotifications.sendLocalNotification("\(dict)", shouldRepeat: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        LocalNotifications.sendLocalNotification("100", shouldRepeat: false)
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            let cbUUID = CBUUID(string: "0003CBB1-0000-1000-8000-00805F9B0131")
            peripheral.discoverCharacteristics([cbUUID], for: service)
        }
        LocalNotifications.sendLocalNotification("108", shouldRepeat: false)
    }
    
    func getRandomColor() -> UIColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
            
            for _ in 0...100 {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                getRandomColor().getRed(&r, green: &g, blue: &b, alpha: &a)
                r = r * 255
                g = g * 255
                b = b * 255
                let bytes: [UInt8] = [UInt8(r), UInt8(g), UInt8(b)]
                let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
                peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                usleep(100000)
            }
            let bytes: [UInt8] = [0, 0, 0]
            let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didupdatenotificationforstate")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        LocalNotifications.sendLocalNotification("123", shouldRepeat: false)
        print(characteristic)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            message = "Bluetooth LE is turned on and ready for communication."
            LocalNotifications.sendLocalNotification("PoweredOn", shouldRepeat: false)
            
            // centralManager.scanForPeripheralsWithServices(nil, options: nil)
            if let nsuuid1 = UUID(uuidString: "A97E74F4-0714-44B3-9A2C-06A141A18B4D") {
                print("here we are")
                let peripherals = centralManager.retrievePeripherals(withIdentifiers: [nsuuid1])
                
                for p in peripherals {
                    peripheral = p
                    print("and here as well")
                    centralManager.connect(p, options: nil)
                }
            }
            
            //            centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID1, sensorTagAdvertisingUUID2, sensorTagAdvertisingUUID3], options: nil)
        }
        
        print(message)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        LocalNotifications.sendLocalNotification("background", shouldRepeat: false)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(String(describing: advertisementData[CBAdvertisementDataLocalNameKey]))\" \(String(describing: peripheral.name)) - \(advertisementData)")
        LocalNotifications.sendLocalNotification("found something", shouldRepeat: false)
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == sensorTagName {
                LocalNotifications.sendLocalNotification("**** SENSOR TAG FOUND! ADDING NOW!!!", shouldRepeat: false)
                print("SENSOR TAG FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        LocalNotifications.sendLocalNotification("\(String(describing: error))", shouldRepeat: false)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        LocalNotifications.sendLocalNotification("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!", shouldRepeat: false)
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        let serviceUUID = CBUUID(string: "0003CBBB-0000-1000-8000-00805F9B0131")
        self.peripheral?.discoverServices([serviceUUID])
    }
}
