//
//  BluetoothSerialWorker.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/5/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

class BluetoothSerialWorker {
    
    private let serialQueue = DispatchQueue(label: "BLEWorkQueue")
    private let semaphore = DispatchSemaphore(value: 0)
    
    var commandQueue : Array<WriteCommand>
    
    init() {
        //self.commandQueue = commands
        self.commandQueue = Array<WriteCommand>()
    }
    
    func clearSemaphore() {
        self.semaphore.signal()
        if self.commandQueue.count > 0 {
            self.commandQueue.removeAll()
        }
    }
    
    func enqueueCommand(command: WriteCommand) {
        self.commandQueue.append(command)
        //let wait = command.waitTime
        var wait = Double(command.waitTime)
        wait = wait/1000
        
        let dispatchTime = DispatchTime.now() + Double(Int64(wait * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        print("WAIT TIME \(dispatchTime)")
        serialQueue.asyncAfter(deadline: dispatchTime) {
            command.execute()
            print("DATA SENT")
            //let d = DispatchTime(uptimeNanoseconds: 1000000000)
            //self.semaphore.wait(timeout: d)
            //print("LOCKING")
            self.semaphore.wait()
        }
//        serialQueue.async {
//            print("WRITING NOW")
//            command.execute()
//            //let d = DispatchTime(uptimeNanoseconds: 1000000000)
//            //self.semaphore.wait(timeout: d)
//            //print("LOCKING")
//            self.semaphore.wait()
//        }
    }
    
    func dequeueCommand() {
        self.commandQueue.removeFirst()
        self.semaphore.signal()
//        serialQueue.async {
//            
//            
//        }
        //self.semaphore.signal()
    }
    
    func queueLength() -> Int {
        return self.commandQueue.count
    }
}

class WriteCommand {
    let peripheral: CBPeripheral!
    let dataString: String!
    let characteristic: CBCharacteristic!
    let charType: CBCharacteristicWriteType!
    let commandNumber: Int!
    let waitTime: Int!
    let defaultWaitTime = 10
    let incrementalWaitTime = 500
    
    
    init(peripheral: CBPeripheral,dataString: String, characteristic: CBCharacteristic,type: CBCharacteristicWriteType, number: Int) {
        self.peripheral = peripheral
        self.dataString = dataString
        self.characteristic = characteristic
        self.charType = type
        self.commandNumber = number
        if(number == 1) {
            self.waitTime = self.defaultWaitTime
        } else {
            self.waitTime = self.defaultWaitTime + (number-1) * (self.incrementalWaitTime)
        }
    }
    
    public func execute() {
        let codeBytes = self.dataString.data(using: String.Encoding.utf8)
        print("JUST BEFORE WRITING \(self.dataString)")
        self.peripheral.writeValue(codeBytes!, for: self.characteristic, type: self.charType)
    }
}
