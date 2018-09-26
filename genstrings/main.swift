#!/usr/bin/env xcrun --sdk macosx swift
//
//  main.swift
//  genstrings
//
//  Created by Kristian Trenskow on 03/04/2017.
//  Copyright © 2017 trenskow. All rights reserved.
//

import Foundation

/// Exits the script because of an error.
func fail(_ error: String) -> Never {
    print("💥  \(error)")
    exit(-1)
}

/// Prints an info message.
func info(_ message: String) {
    print("ℹ️  \(message)")
}

/// Prints a success message and exits the script.
func success(_ message: String) -> Never {
    print("✅  \(message)")
    exit(0)
}

/// Gets an environment variable value with the given name.
func getEnvironmentValue(key: String) -> String? {
    guard let rawValue = getenv(key) else {
        return nil
    }
    
    return String(cString: rawValue)
}

info("looking for strings to localize")

let exp = try! NSRegularExpression(pattern: "(?<=\")([^\"]*)(?=\".(localize\\((\\\"(.*?)\\\")?\\)))", options: [])

func findFiles(path: String) throws -> [String] {
    return try FileManager.default.contentsOfDirectory(atPath: path).reduce([], { (result, subpath) -> [String] in
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: "\(path)/\(subpath)", isDirectory: &isDirectory) else { return result }
        guard isDirectory.boolValue == false else {
            return try result + findFiles(path: "\(path)/\(subpath)")
        }
        return result + ["\(path)/\(subpath)"]
    }).filter({ (path) -> Bool in
        path.contains(".swift")
    })
}

/// Returns the output file.
func getOutput() -> URL {
    guard let plistPath = getEnvironmentValue(key: "SCRIPT_OUTPUT_FILE_0") else {
        fail("an output file needs to be set.")
    }
    
    return URL(fileURLWithPath: plistPath)
}

var path: String? = nil

if (CommandLine.arguments.count > 1) {
    path = CommandLine.arguments[1]
}

let outputURL = getOutput()

try? FileManager.default.removeItem(at: outputURL)

do {
    try "".write(to: outputURL, atomically: true, encoding: .utf16BigEndian)
    
    let writeOutput = try FileHandle(forWritingTo: outputURL)
    writeOutput.write(Data(bytes: [0xfe, 0xff]))
    writeOutput.write(try findFiles(path: path ?? FileManager.default.currentDirectoryPath)
        .map { (path) -> [(String, String?)] in
            
            let data = try! Data(contentsOf: URL(fileURLWithPath: path))
            
            let string = String(data: data, encoding: .utf8)!
            
            return exp.matches(in: string, options: [], range: NSMakeRange(0, string.count)).reduce([], { (ret, result) -> [(String, String?)] in
                
                let found = (0 ..< result.numberOfRanges).map({ (idx) -> String? in
                    let range = result.rangeAt(idx)
                    guard range.location != NSNotFound else { return nil }
                    let startIndex = string.index(string.startIndex, offsetBy: range.location)
                    let endIndex = string.index(startIndex, offsetBy: range.length)
                    return String(string[startIndex..<endIndex])
                })
                
                return ret + [(found.first!!, found.last!)]
                
            })
            
        }
        .reduce([], +)
        .reduce([]) { (result, strings) -> [(String, String?)] in
            guard !result.contains(where: { $0.0 == strings.0 }) else { return result }
            return result + [strings]
        }
        .map { (strings) in
            let comment = strings.1 ?? "No comment provided by engineer"
            let string = strings.0.components(separatedBy: "\"").joined(separator: "\\\"")
            info("\(string) : \(comment)")
            return ["", "/* \(comment) */", "\"\(string)\" = \"\(string)\";"]
        }
        .reduce([], +)
        .joined(separator: "\n")
        .data(using: .utf16BigEndian)!)
} catch let error as NSError {
    fail("error when opening output - \(error.localizedDescription)")
}
