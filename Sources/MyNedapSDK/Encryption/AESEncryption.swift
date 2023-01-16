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
    let constZero: Array<UInt8> = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] // ivzero length = 16
    
    public init(masterKey: String, uidaKey: String) {
        self.masterKey = masterKey
        self.uidaKey = uidaKey
    }
    
    func keyGen () -> String {
        
        let l = try! AES(key: masterKey.hexaToBytes, blockMode: CBC(iv:constZero),padding: .noPadding).encrypt(constZero)
        var binaryString = l.toHexString().hexaToBinary
        
        if String(binaryString[0]) == "0" {
            binaryString = binaryString + "0"
            binaryString.removeFirst()
        }
        else {
            binaryString = binaryString + "0"
            binaryString.removeFirst()
        }

//        let constRb2 = BigInteger(constRb,radix: 2)

        var k1Binary: String = binaryString
        let k1Hex:String = binToHex(binaryString)
        
        if String(k1Binary[0]) == "0" {
            k1Binary = k1Binary + "0"
            k1Binary.removeFirst()
        } else {
            k1Binary = k1Binary + "0"
            k1Binary.removeFirst()
        }
        
        let k2Binary: String = k1Binary
        let k2Hex:String = binToHex(k1Binary)
        
        let m = "01" + uidaKey
        var padding = ""
            padding = "8000000000000000000000"
            padding = "80000000000000000000000000000000"
//            padding = "80000000000000000000000000000000000000000000"
        
        let d = m + padding
        let dLast16 = String(d[32...63])
        let dFirst16 = String(d[...31])

        let xork2 = BigInteger(dLast16.hexaToBinary,radix: 2)! ^ BigInteger(k2Binary,radix: 2)!

        let dk12 = dFirst16 + binToHex(String(xork2,radix: 2))
        
        let dkAes = try! AES(key: masterKey.hexaToBytes, blockMode: CBC(iv: constZero),padding: .noPadding).encrypt(dk12.hexaToBytes)
        
        let keyaBinary = dkAes.toHexString().hexaToBinary
        let keya = String(binToHex(keyaBinary)[32...])
        let keya64 = String(binToHex(keyaBinary))
        
        print("keya::: \(keya64)") // EC0846CED40303072EEB86E45F7B5D641F9EF724B450FFD232E7EB0FBBF820A6
        print("key1::: \(k1Hex)")
        print("key2::: \(k2Hex)")
        print("d:::::: \(d)") // 01570000001A00000000000002026073 80000000000000000000000000000000000000000000
        // 01570000001A00000000000002026073 80000000000000000000000000000000
        print("dk12::: \(dk12)")
        
        return keya
    }
    
    func aes128Operation (rndaRndbAsteric:String, keya:String) -> String  {
        let keyaHex = keya.hexaToBytes // B0A42687AA50A67A6DCEB68EA59A1332
        let rndarndbHex = rndaRndbAsteric.hexaToBytes
        let k = try! AES(key: keyaHex, blockMode: CBC(iv: constZero),padding: .noPadding).encrypt(rndarndbHex)
        
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
        var randomHexString:String = ""

        for _ in 1...16 {
            if let randomNumber = hexArray.randomElement() {
                randomNumbers.append(randomNumber)
                randomHexString += randomNumber
            }
        }
        
        let keya = keyGen()
        let rndbAsteric = rndbAsteric(value: response)
        let finalValue = randomHexString + rndbAsteric
    
        let uida = aes128Operation(rndaRndbAsteric: finalValue, keya: keya)
        
        return uida
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
