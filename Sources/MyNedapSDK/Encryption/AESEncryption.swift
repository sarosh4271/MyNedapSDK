//
//  File.swift
//  
//
//  Created by Sarosh Tahir on 12/01/2023.
//

import Foundation
import CryptoSwift

public final class AESEncryption {
    var masterKey:String // from user as input
    var uidaKey:String // from user as input

    private let const_rb: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x87]
    private let const_zero: Array<UInt8> = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
    private var rnda: String = ""
    
    public init(masterKey: String, uidaKey: String) {
        self.masterKey = masterKey
        self.uidaKey = uidaKey
    }
    
    func keyGen () -> String {
        
        let l = try! AES(key: masterKey.hexaToBytes, blockMode: CBC(iv:const_zero),padding: .noPadding).encrypt(const_zero)
        var binaryString = l.toHexString().hexaToBinary
        
        if String(binaryString[0]) == "0" {
            binaryString = binaryString + "0"
            binaryString.removeFirst()
        }
        else {
            binaryString = binaryString + "0"
            binaryString.removeFirst()
        }

        var k1Binary: String = binaryString
        let k1Hex:String = binToHex(binaryString)
        
        var k2Binary: String = k1Binary
        
        if (String(k1Binary[0]) == "0") {
            var leftShift = k1Binary + "0"
            leftShift.removeFirst()
            k2Binary = leftShift
        } else {
            var leftShift = k1Binary + "0"
            leftShift.removeFirst()
            let xor = BigInteger(leftShift,radix: 2)! ^ BigInteger(const_rb.toHexString().hexaToBinary,radix: 2)!
            k2Binary = String(xor,radix: 2)
        }
        
        let k2Hex:String = binToHex(k2Binary)
        
        var m = "01" + uidaKey + "80"
        while m.count < 64 {
            m = m + "0"
        }
        
        let d = m
        let dLast16 = String(d[32...63])
        let dFirst16 = String(d[...31])

        let xork2 = BigInteger(dLast16.hexaToBinary,radix: 2)! ^ BigInteger(k2Binary,radix: 2)!

        let dk12 = dFirst16 + binToHex(String(xork2,radix: 2))
        
        let dkAes = try! AES(key: masterKey.hexaToBytes, blockMode: CBC(iv: const_zero),padding: .noPadding).encrypt(dk12.hexaToBytes)
        
        let keyaBinary = dkAes.toHexString().hexaToBinary
        let keya = String(binToHex(keyaBinary)[32...])
        let keya64 = String(binToHex(keyaBinary))
        
        print("keya::: \(keya64)")
        print("key1::: \(k1Hex)")
        print("key2::: \(k2Hex)")
        print("constzero \(const_rb.toHexString())")
        print("d:::::: \(d)")
        print("dk12::: \(dk12)")
        return keya
    }
    
    
    func aes128Operation (rndaRndbAsteric:String, keya:String) -> String  {
        let keyaHex = keya.hexaToBytes // B0A42687AA50A67A6DCEB68EA59A1332
        let rndarndbHex = rndaRndbAsteric.hexaToBytes
        let k = try! AES(key: keyaHex, blockMode: CBC(iv: const_rb),padding: .noPadding).encrypt(rndarndbHex)
        
        let result = "42" + k.toHexString()
      return result;
    }
    
    func getDataFromValue (value:String) -> Data {
        let value_uida = value
        var toW: String = ""
        toW = value_uida
        guard let valueString = toW.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) else {return Data()}
        return valueString
    }
    
    func writeThird (response:String) -> String {
        let hexArray: Array<String> = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A","B","C","D","E","F"]
        var randomNumbers = [String]()

        for _ in 1...16 {
            if let randomNumber = hexArray.randomElement() {
                randomNumbers.append(randomNumber)
                rnda += randomNumber
            }
        }
        
        let keya = keyGen()
        let rndbAsteric = rndbAsteric(value: response)
        let finalValue = rnda + rndbAsteric
    
        let uida = aes128Operation(rndaRndbAsteric: finalValue, keya: keya)
        
        return uida
    }
    
    func decryptOperation (response:String) -> Bool {
        let keya = keyGen()
        var newResponse = String(response[2...])
        
        let l = try! AES(key: keya.hexaToBytes, blockMode: ECB(),padding: .noPadding).decrypt(newResponse.hexaToBytes)
        
        var randomRotated:[UInt8] = []
        for item in l {
            if randomRotated.count < Int(l.count/2) {
                randomRotated.append(item)
            }
        }
    
        let result = rotateLeft(arr: rnda.hexaToBytes)
        if result == randomRotated {
            return true
        } else {
            return false
        }
    }
    
    private func rotateLeft(arr: [UInt8]) -> [UInt8] {
        guard arr.count >= 2 else {
        return arr
        }
        let head = [arr[0]]
        let tail = Array(arr[1..<arr.count])
        return tail + head
    }
    
    func rndbAsteric(value:String) -> String {
        let subData = value[2...]
        let shiftedValue = subData[0...1];
        let subData2 = String(subData[2...])
        let afterShift:String = String(subData2 + shiftedValue);
      return afterShift
    }
    
    func binToHex(_ bin : String) -> String {
        // binary to integer:
        guard let num = BigInteger(bin, radix: 2) else { return "" }
        // integer to hex:
        let hex = String(num, radix: 16, uppercase: true) // (or false)
        return hex
    }
}
