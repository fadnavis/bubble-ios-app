//
//  BluetoothSerialMain.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/4/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

var serialMain: BluetoothSerialMain!

protocol BubbleWriteProcessDelegate {
    func BubbleWriteStarted()
    func BubbleWriteEnded()
    func BubbleWriteEndedWithError()
    func BubbleWriteBLEOff()
}

final class BluetoothSerialMain: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let sharedInstance = BluetoothSerialMain()
    private let blesemaphore = DispatchSemaphore(value: 0)
    
    var bubbleDevice: CBPeripheral?
    var centralManager: CBCentralManager!
    let bleWorkQueue = DispatchQueue(label: "com.bubble.bleMain", qos: .userInitiated,target: nil)
    var dataArray: [String]?
    var medium: String!
    var isConfiguring: Bool!
    let codesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
    var writeType: CBCharacteristicWriteType = CBCharacteristicWriteType.withoutResponse
    var writeDelegate: BubbleWriteProcessDelegate?
    var cancelTimer: Timer?
    var isSending = false
    var isBLEOn: Bool?
    var tvCodeString = ""
    var bleQueue: DispatchQueue!
    
    override private init() {
        super.init()
        bleQueue = DispatchQueue(label: "com.bubble.bleEvents", qos: .userInitiated, target: nil)
        centralManager = CBCentralManager(delegate: self, queue: bleQueue, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        let defaults = UserDefaults.standard
        if let bubbleUUIDString = defaults.value(forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER) as? String {
            let bubbleUUID = UUID(uuidString: bubbleUUIDString)
            let foundPeripherals = centralManager.retrievePeripherals(withIdentifiers: [bubbleUUID!])
            for peripheral in foundPeripherals {
                self.bubbleDevice = peripheral
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(BluetoothSerialMain.applicationDidEnterBackground), name: Notification.Name(NotificationKeys().ApplicationDidEnterBackground), object: nil)
    }
    
    func applicationDidEnterBackground() {
        writeDelegate?.BubbleWriteEnded()
        disconnectBLE()
        guard let ctimer = cancelTimer else {
            return
        }
        if(ctimer.isValid) {
            ctimer.invalidate()
        }
    }
    
    func setWriteProcessDelegate(delegate: BubbleWriteProcessDelegate) {
        self.writeDelegate = delegate
    }
    
    func removeWriteProcessDelegate() {
        self.writeDelegate = nil
    }
    
    func setRemoteCodes(codeArray: [String], medium: String) {
        self.dataArray = codeArray
        self.medium = medium
        self.isConfiguring = false
    }
    
    func setTVCodeString(dataString: String) {
        self.tvCodeString = dataString
        self.medium = "TV"
        self.isConfiguring = true
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //doing nothing at the moment. TODO
        switch central.state {
        case .poweredOn:
            if isBLEOn == nil {
                isBLEOn = true
                resetBluetooth()
                blesemaphore.signal()
            } else {
                isBLEOn = true
                resetBluetooth()
            }

        case .poweredOff:

            if isBLEOn == nil {
                isBLEOn = false
                blesemaphore.signal()
            } else {
                isBLEOn = false
            }
        default:
            break
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
    }
    
    func setIsSending(sending: Bool) {
        self.isSending = sending
    }
    
    func getIsSending() -> Bool {
        return self.isSending
    }
    
    func startProcessBubble() {
        if isBLEOn == nil {
            blesemaphore.wait()
        }

        guard let isbleon = isBLEOn else {
            return
        }
        
        if(isbleon == true) {
            self.setIsSending(sending: true)
            guard let device = self.bubbleDevice else {
                //redirect to the setup page or let a delegate inform the subscribers
                self.setIsSending(sending: false)
                DispatchQueue.main.async {
                    if let dele = self.writeDelegate {
                        dele.BubbleWriteEndedWithError()
                    }
                }
                return
            }
            DispatchQueue.main.async {
                if let dele = self.writeDelegate {
                    dele.BubbleWriteStarted()
                }
                self.cancelTimer = Timer.scheduledTimer(timeInterval: TimeInterval(GlobalConstants.DISCONNECT_BLE_TIMER), target: self, selector: #selector(self.disconnectBLE), userInfo: nil, repeats: false)
            }
            centralManager.connect(device, options: nil)
            if let ctimer = cancelTimer {
                if ctimer.isValid {
                    ctimer.invalidate()
                }
            }
        } else {
            showBLEOffALert()
        }
    }
    
    func showBLEOffALert() {
        DispatchQueue.main.async {
            if let dele = self.writeDelegate {
                dele.BubbleWriteBLEOff()
            }
        }
    }
    
    func disconnectBLE() {
        if let bd = self.bubbleDevice {
            centralManager.cancelPeripheralConnection(bd)            
            if (isSending == true) {
                self.isSending = false
                DispatchQueue.main.async {
                    if let dele = self.writeDelegate {
                        dele.BubbleWriteEndedWithError()
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: GlobalConstants.BubbleDevice.HM_RX_TX_SERVICE)])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.setIsSending(sending: false)
        DispatchQueue.main.async {
            if let dele = self.writeDelegate {
                dele.BubbleWriteEndedWithError()
            }
        }
        
    }
    
    //MARK: Peripheral delegate functions
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services {
            let bubbleService = service[0]
            peripheral.discoverCharacteristics([CBUUID(string: GlobalConstants.BubbleDevice.HM_RX_TX)], for: bubbleService)
        }
    }
    
    let bleWriteQueue = BluetoothSerialWorker()
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //if no error, start writing process
        var tx: CBCharacteristic?
        if let characteristics = service.characteristics {
            for ch in characteristics {
                tx = ch
            }
            if let blechar = tx {
                peripheral.setNotifyValue(true, for: blechar)
            }
        }
        
        if(self.isConfiguring == false) {
            if let dataarray = dataArray {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.dataStoreController.inContext { context in
                    guard let context = context else {
                        self.setIsSending(sending: false)
                        
                        DispatchQueue.main.async {
                            if let dele = self.writeDelegate {
                                dele.BubbleWriteEndedWithError()
                            }
                        }
                        return
                    }
                    var i = 1
                    self.bleWriteQueue.clearSemaphore()

                    
                    for data in dataarray {
                        //var codeResult: [NSManagedObject]
                        let predicate = NSPredicate(format: "(medium = %@) AND (remoteNumber = %@)", argumentArray: [self.medium,data])
                        self.codesFetchRequest.predicate = predicate
                        
                        do {
                            let codeResult = try context.fetch(self.codesFetchRequest) as! [NSManagedObject]
                            if(codeResult.count > 0) {
                                let remoteCodeObject = codeResult[0]
                                var datastring = ""
                                if let remoteprotocol = remoteCodeObject.value(forKey: "protocol") as? String, let hexcode = remoteCodeObject.value(forKey: "hexcode") as? String, let codebits = remoteCodeObject.value(forKey: "bits") as? String, let address = remoteCodeObject.value(forKey: "address") as? String {
                                    datastring = remoteprotocol
                                    datastring += ":"
                                    datastring += address
                                    datastring += ":"
                                    datastring += hexcode
                                    datastring += ":"
                                    datastring += codebits
                                    datastring += ":"
                                    print(datastring)
                                    let command = WriteCommand(peripheral: peripheral, dataString: datastring, characteristic: tx!, type: self.writeType, number: i)
                                    self.bleWriteQueue.enqueueCommand(command: command)
                                    i += 1
                                }
                            }
                        } catch {
                            self.setIsSending(sending: false)
                            DispatchQueue.main.async {
                                if let dele = self.writeDelegate {
                                    dele.BubbleWriteEndedWithError()
                                }
                            }
                        }
                        
                    }
                }
            }
        } else if (self.medium == "TV") {
            self.bleWriteQueue.clearSemaphore()
            let command = WriteCommand(peripheral: peripheral, dataString: self.tvCodeString, characteristic: tx!, type: self.writeType, number: 1)
            self.bleWriteQueue.enqueueCommand(command: command)
        }
        //peripheral.writeValue(<#T##data: Data##Data#>, for: tx!, type: writeType)
    }
        
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        bleWriteQueue.dequeueCommand()
//        print("DEQUEUED")
//        if(bleWriteQueue.queueLength() == 0) {
//            self.setIsSending(sending: false)
//            DispatchQueue.main.async {
//                if let dele = self.writeDelegate {
//                    dele.BubbleWriteEnded()
//                }
//            }
//            //don't cancel but reset the views
//            //centralManager.cancelPeripheralConnection(peripheral)
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("DID UPDATE VALUE")
        bleWriteQueue.dequeueCommand()
        print("DEQUEUED")
        if let response = characteristic.value {
            if let str = NSString(data: response, encoding: String.Encoding.utf8.rawValue) as? String {
                print("RESPONSE \(str)")
            }
            
        }
        
        if(bleWriteQueue.queueLength() == 0) {
            self.setIsSending(sending: false)
            peripheral.setNotifyValue(false, for: characteristic)
            DispatchQueue.main.async {
                if let dele = self.writeDelegate {
                    dele.BubbleWriteEnded()
                }
            }
            //don't cancel but reset the views
            //centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
}
