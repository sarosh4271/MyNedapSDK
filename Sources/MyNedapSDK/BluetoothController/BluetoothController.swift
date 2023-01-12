//
//  File.swift
//  
//
//  Created by Sarosh Tahir on 12/01/2023.
//

import Foundation
import CoreBluetooth
import SwiftUI

@available(iOS 13.0, *)
public final class BleViewController: UIViewController, ObservableObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    @Published var loglist : Array<String> = []
    @Published var devicesFound : [CBPeripheral] = []

    var device : CBPeripheral!
    var masterKey : String = ""
    var uidaKey : String = ""
        
    private var centralManager: CBCentralManager!
    private var aesEncryption : AESEncryption!
    private var isBluetoothOn : Bool = false
    private var charRepWriteTx : CBCharacteristic?
    private var charRepNotifyRx : CBCharacteristic?
    private var charRepWriteID : CBCharacteristic?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        aesEncryption = AESEncryption(masterKey: masterKey, uidaKey: uidaKey)
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                isBluetoothOn = false
                print("Bluetooth is powered off")
            case .poweredOn:
                isBluetoothOn = true
                print("Bluetooth is on")
            case .unauthorized:
                isBluetoothOn = false
                print("Unauthorized for bluetooth")
            case .unknown:
                isBluetoothOn = false
                print("Unknown bluetooth case")
            case .resetting:
                isBluetoothOn = false
                print("Bluetooth resetting")
            case .unsupported:
                isBluetoothOn = false
                print("Unsupported bluetooth case")
            @unknown default:
                isBluetoothOn = false
                print("Default bluetotoh case")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)  {
        peripheral.discoverServices(nil)
        peripheral.delegate = self
        let c = aesEncryption.keyGen()
        print("Connected to device \(c)")

        loglist.append("Connected successfully to \(peripheral.name ?? "")")
    }
    
    func stopScanning (){
        centralManager.stopScan()
    }
    
    func startScanning () {
        if isBluetoothOn {
            devicesFound = []
            centralManager.scanForPeripherals(withServices: [])
        }
    }
    
    func connectToDevice(dev:CBPeripheral){
        loglist = []
        print("Starting to connect")
        loglist.append("starting to connect")
        centralManager.connect(dev)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name != nil && !devicesFound.contains(peripheral)
        {
            devicesFound.append(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from device")
        loglist.append("disconnected from device")
    }

    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        for ser in services {
            if ser.uuid == CBUUIDs.BLEService_UUID {
                peripheral.discoverCharacteristics(nil, for: ser)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("error while writing value to descriptor: \(error)")
            loglist.append("error while writing value to descriptor: \(descriptor.uuid.uuidString)")
        } else {
            print("write success! descriptor ", descriptor.uuid.uuidString)
                     loglist.append("write success for descriptor to: \(descriptor.uuid.uuidString)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("notification update state: \(characteristic.isNotifying)")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else {return}
        for c in chars {
            if c.uuid == CBUUIDs.BLENotifyChar_UUID {
                charRepNotifyRx = c
                loglist.append("notification char found! \(charRepNotifyRx!.uuid.uuidString)")
            }
            if c.uuid == CBUUIDs.BLEChar_UUID {
                charRepWriteID = c
                loglist.append("write char found \(charRepWriteID?.uuid.uuidString ?? "empty")")
            }
            if c.uuid == CBUUIDs.BLEWriteChar_UUID {
                charRepWriteTx = c
                loglist.append("write char found \(charRepWriteTx?.uuid.uuidString ?? "empty")")
            }
        }
        
        peripheral.setNotifyValue(true, for: charRepNotifyRx!)
        print("notification is on")
        writeMethod(char: charRepWriteID!, peripheral: peripheral,value: aesEncryption.getDataFromValue(value: uidaKey))
    }
    
    private func writeMethod (char : CBCharacteristic, peripheral:CBPeripheral,value:Data) {
        let st = String(decoding: value,as: UTF8.self)
        loglist.append("writing following value: \(st)")
        peripheral.writeValue(value, for: char ,type: .withResponse)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var characteristicASCIIValue = ""

        guard let characteristicValue = characteristic.value else {return}
                 
             let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue)

        characteristicASCIIValue = String(ASCIIstring ?? "")
        loglist.append("got response: \((characteristicASCIIValue as String))")
        print("got response: \((characteristicASCIIValue as String))")
        
        if characteristicASCIIValue.isEmpty == false {
            let sub = String(characteristicASCIIValue[0...1])
            if sub == "41" {
                let uida = aesEncryption.writeThird(response: characteristicASCIIValue)
                
                print("uida values: \(uida)")
                writeMethod(char: charRepWriteTx!, peripheral: peripheral, value: aesEncryption.getDataFromValue(value: uida))
            }
            if sub == "43" {
                peripheral.setNotifyValue(false, for: characteristic)
                loglist.append("3 step completed")
                print("3 step completed")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("write success to: ", characteristic.uuid.uuidString)
        loglist.append("write success to: \(characteristic.uuid.uuidString)")
    }
}
