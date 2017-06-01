//
//  BluetoothSerial.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/30/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreBluetooth

var serial: BluetoothSerial!

protocol BluetoothSerialDelegate {
    func setupStatusChanged(_ status: GlobalConstants.BubbleSetupStatus)
}

protocol BluetoothPeripheralDelegate {
    
}

final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate : BluetoothSerialDelegate!
    var bubbleFound = false
    var centralManager : CBCentralManager!
    weak var writeCharacteristic: CBCharacteristic?
    var writeType: CBCharacteristicWriteType = CBCharacteristicWriteType.withResponse
    var bubbleDevice: CBPeripheral?
    var cancelTimer: Timer?

    
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        let bleQueue = DispatchQueue.global(qos: .default)
        centralManager = CBCentralManager(delegate: self, queue: bleQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    func startScan() {
        self.bubbleFound = false
        DispatchQueue.main.async {
            self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.in_PROGRESS)
            self.cancelTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BluetoothSerial.stopProcess), userInfo: nil, repeats: false)
        }
        
        guard centralManager.state == .poweredOn else {
            DispatchQueue.main.async {
                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
            }
            return
        }
        let uuid = CBUUID(string: "FFE0")
        centralManager.scanForPeripherals(withServices: [uuid], options: nil)        
    }
    
    //This runs on the main thread
    func stopProcess() {
        centralManager.stopScan()
        if(!self.bubbleFound) {
            self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
        if(!self.bubbleFound) {
            DispatchQueue.main.async {
                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
            }
        }
    }
    
    func resetBluetooth() {
        //        centralManager = CBCentralManager(delegate: self, queue: bleQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        let defaults = UserDefaults.standard
        if let bubbleUUIDString = defaults.value(forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER) as? String {
            let bubbleUUID = UUID(uuidString: bubbleUUIDString)
            let foundPeripherals = centralManager.retrievePeripherals(withIdentifiers: [bubbleUUID!])
            for peripheral in foundPeripherals {
                self.bubbleDevice = peripheral
            }
        }
        cancelConnection(peripheral: self.bubbleDevice)
    }
    
    func cancelConnection(peripheral: CBPeripheral?) {
        guard let per = peripheral else {
            return
        }
        centralManager.cancelPeripheralConnection(per)
    }
    
    //MARK: CentralManager Delegate functions
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScan()
        //case .poweredOff:
            //show alert for power off
            
        default:
            break
        }
    }
    
    func showBLEOffALert() {
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: GlobalConstants.BubbleDevice.HM_RX_TX_SERVICE)])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        DispatchQueue.main.async {
            self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(peripheral.name == GlobalConstants.BubbleDevice.BUBBLE_DEVICE_NAME) {
            self.bubbleFound = true
            stopScan()
            self.bubbleDevice = peripheral
            let userDefaults = UserDefaults.standard
//            if let initialdeviceUUIDString = userDefaults.value(forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER) as? String {
//                if (initialdeviceUUIDString != peripheral.identifier.uuidString) {
//                    
//                } else {
//                    userDefaults.set(peripheral.identifier.uuidString, forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER)
//                    peripheral.delegate = self
//                    centralManager.connect(self.bubbleDevice!, options: nil)
//                }
//            } else {
//                
//            }
            userDefaults.set(peripheral.identifier.uuidString, forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER)
            peripheral.delegate = self
            centralManager.connect(self.bubbleDevice!, options: nil)
        }
    }
    
//    func verifyBubbleDevice(uuidString: String) {
//        let bubblecall = CallBubbleApi()
//        bubblecall.delegate = self
//        var params :  [String: String] = [:]
//        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_VERIFY_DEVICE
//        params["emailid"] = UserData.sharedInstance.userEmail
//        params["deviceid"] = uuidString
//        bubblecall.post(params)
//    }
    
//    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
//        <#code#>
//    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }
    
    //MARK: Peripheral Delegate functions
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
            }
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        if let service = peripheral.services {
            //there should be only one service
            let bubbleService = service[0]
            peripheral.discoverCharacteristics([CBUUID(string: GlobalConstants.BubbleDevice.HM_RX_TX)], for: bubbleService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
            }
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        var tx: CBCharacteristic?
        if let characteristics = service.characteristics {
            for ch in characteristics {
                tx = ch
            }
            if let blechar = tx {
                peripheral.setNotifyValue(true, for: blechar)
                let macaddressapi = GlobalConstants.BubbleAPI.GET_MAC_ID
                let codeBytes = macaddressapi.data(using: String.Encoding.utf8)
                peripheral.writeValue(codeBytes!, for: blechar, type: .withoutResponse)
            }
        }
//        if let _ = service.characteristics {
//            //done with all the discovery
//            DispatchQueue.main.async {
//                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.all_OK)
//            }
//            self.bubbleFound = true
//            centralManager.cancelPeripheralConnection(peripheral)
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            DispatchQueue.main.async {
                self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE)
            }
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        if let response = characteristic.value {
            if let str = NSString(data: response, encoding: String.Encoding.utf8.rawValue) as? String {
                UserDefaults.standard.set(str, forKey: GlobalConstants.UserDefaults.BUBBLE_MAC_ID)
                let usershared = UserData.sharedInstance
                usershared.bubbleMAC = str
                peripheral.setNotifyValue(false, for: characteristic)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate.setupStatusChanged(GlobalConstants.BubbleSetupStatus.all_OK)
        }
        self.bubbleFound = true
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
}
