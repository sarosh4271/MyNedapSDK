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
public class BleViewController: UIViewController, ObservableObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    @Published public var loglist : Array<String> = []
    @Published public var devicesFound : [CBPeripheral] = []
    @Published public var deviceNameMAC : Array<String> = []
    @Published public var isConnected : Bool = false
    @Published public var isBluetoothOn : Bool = false
    @Published public var authenticated : Bool = false


    var masterKey : String = ""
    var uidaKey : String = ""
    private var userDistance : Double = 0
    private var measuredPower : Double = 3
    private var nFactor : Double = 4
    private var devicesDistance : Array<Double> = []

    private var device : CBPeripheral!
    private var centralManager : CBCentralManager!
    private var aesEncryption : AESEncryption!
    private var charRepWriteTx : CBCharacteristic?
    private var charRepNotifyRx : CBCharacteristic?
    private var charRepWriteID : CBCharacteristic?
    
    public init () {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                isBluetoothOn = false
                print("Bluetooth is powered off")
            case .poweredOn:
                isBluetoothOn = true
                print("Bluetooth is ons")
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
        isConnected = true
        loglist.append("Connected successfully to \(peripheral.name ?? "")")
    }
    
    public func stopScanning (){
        centralManager.stopScan()
        devicesFound = []
    }
    
    public func startScanning (distance:Double) {
        userDistance = distance
        if isBluetoothOn {
            devicesFound = []
            centralManager.scanForPeripherals(withServices: [])
        }
    }
    
    public func connectAndAuthenticate(dev:CBPeripheral,master_key:String,uida_key:String) {
        loglist = []
        authenticated = false
        isConnected = false
        masterKey = master_key
        uidaKey = uida_key
        aesEncryption = AESEncryption(masterKey: masterKey, uidaKey: uidaKey)
        device = dev
        loglist.append("starting to connect")
        centralManager.stopScan()
        centralManager.connect(dev)
    }
    
    public func scanConnectAuthenticate (distance:Double,master_key:String,uida_key:String) {
        loglist = []
        userDistance = distance
        authenticated = false
        isConnected = false
        masterKey = master_key
        uidaKey = uida_key
        aesEncryption = AESEncryption(masterKey: masterKey, uidaKey: uidaKey)
        loglist.append("Scanning for devices")
        centralManager.scanForPeripherals(withServices: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.centralManager.stopScan()
            if !self.devicesFound.isEmpty {
                self.closestDevice()
            } else {
                self.loglist.append("No devices found!")
            }
        }
    }
    
    private func closestDevice () {
        var minDistance = devicesDistance.first ?? 0
        device = devicesFound.first

        for i in 0..<devicesDistance.count {
            if devicesDistance[i] < minDistance {
                minDistance = devicesDistance[i]
                device = devicesFound[i]
            }
        }
        
        loglist.append("Starting to connect")
        centralManager.connect(device)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let disDouble = pow(10, ((measuredPower - Double(truncating: RSSI)) / (10 * nFactor)))

        if peripheral.name != nil && !devicesFound.contains(peripheral) && disDouble < (userDistance/100) {
            devicesFound.append(peripheral)
            devicesDistance.append(disDouble)
            deviceNameMAC = [peripheral.name ?? "",peripheral.identifier.uuidString]
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
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
    
    func writeToDescriptor (descriptor:CBDescriptor, peripheral:CBPeripheral) {
        let dataValue = Data([0x01, 0x00])
        _ = CBCharacteristicWriteType.withResponse
        loglist.append("Writing to descriptor: [0]")
        if descriptor.characteristic?.properties.contains(.write) == true {
//            do {
//                try
            peripheral.writeValue(dataValue, for: descriptor)
//            } catch let exception {
//                // An exception occurred while writing the value.
//                print("Exception while value to descriptor: \(exception)")
//                loglist.append("error while writing value to descriptor: \(exception)")
//            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            loglist.append("error while writing value to descriptor: \(descriptor.uuid.uuidString) , error \(error)")
        } else {
                     loglist.append("write success for descriptor to: \(descriptor.uuid.uuidString)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
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
//        peripheral.discoverDescriptors(for: charRepNotifyRx!)
        writeMethod(char: charRepWriteID!, peripheral: peripheral,value: aesEncryption.getDataFromValue(value: uidaKey))
    }
    
    private func writeMethod (char : CBCharacteristic, peripheral:CBPeripheral,value:Data) {
        let st = String(decoding: value,as: UTF8.self)
        loglist.append("writing following value: \(st)")
        peripheral.writeValue(value, for: char ,type: .withResponse)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {

        guard let descList = characteristic.descriptors else {return}
        if descList.count > 0 {
            guard let desc = descList.first else {return}
            desc.characteristic?.service?.peripheral?.setNotifyValue(true, for: desc.characteristic!)
            writeToDescriptor(descriptor: desc, peripheral: peripheral)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var characteristicASCIIValue = ""

        guard let characteristicValue = characteristic.value else {return}
                 
             let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue)

        characteristicASCIIValue = String(ASCIIstring ?? "")
        loglist.append("got response: \((characteristicASCIIValue as String))")
        
        if characteristicASCIIValue.isEmpty == false {
            let sub = String(characteristicASCIIValue[0...1])
            if sub == "41" {
                let uida = aesEncryption.writeThird(response: characteristicASCIIValue)
                
                writeMethod(char: charRepWriteTx!, peripheral: peripheral, value: aesEncryption.getDataFromValue(value: uida))
            }
            if sub == "43" {
                let auth_result = aesEncryption.decryptOperation(response: characteristicASCIIValue)
                peripheral.setNotifyValue(false, for: characteristic)

                if auth_result {
                    loglist.append("3 step completed")
                    authenticated = true
                } else {
                    loglist.append("3 step auth result do not match")
                    authenticated = false
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        loglist.append("write success to: \(characteristic.uuid.uuidString)")
    }
}
