//
//  Constants.swift
//  SymetricCrypto
//
//  Created by Ravi Raja Jangid on 11/01/25.
//

import Foundation
// Enhanced debug logging function
func dlog(_ str: String, file: String = #file, function: String = #function, line: Int = #line) {
  
#if DEBUG
        let url = URL(fileURLWithPath: file)
        let fileNameWithExtension = url.lastPathComponent
    if #available(iOS 15, *) {
        print(" ### ET:\(Date.now.timeIntervalSince1970) File:\(fileNameWithExtension) function: \(function) Line No:\(line), Log: \(str)")
    } else {
        print("###File:\(fileNameWithExtension) function: \(function) Line No:\(line), Log: \(str)")
    }
#endif
   
}



struct GlobalConstant {
    static let badgeBlinkTiming = 0.8
}

func decodeToModel<T: Decodable>(json: String) -> T {
    do {
        let jsonData = json.data(using: .utf8)!
        let model = try JSONDecoder().decode(T.self, from: jsonData)
        print("Model is parsable \(T.self)")
        return model
    } catch {
        fatalError("\(T.self) Error decoding JSON: \(error)")

    }
}
class Util {
    
    static var shortVersion: String {
        if let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return buildVersion
        }
        return "1.0"
    }
    
    static var buildVersion: String {
        if let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return buildVersion
        }
        return "1.0"
    }
    
    static var bundleId: String {
        
        if let bundleID = Bundle.main.bundleIdentifier {
            return bundleID
        }
        return "com.ibindsystems.entitydatalocker"
    }
}
func loadJsonData<T: Decodable>(filename: String, as type: T.Type) -> T? {
    // Locate the JSON file in the bundle
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
        print("Failed to locate \(filename).json in bundle.")
        return nil
    }

    do {
        // Load the data from the file
        let data = try Data(contentsOf: url)
        // Decode the JSON data into the specified type
        let decodedData = try JSONDecoder().decode(T.self, from: data)
        return decodedData
    } catch {
        print("Failed to load \(filename) from bundle: \(error)")
        return nil
    }
}
