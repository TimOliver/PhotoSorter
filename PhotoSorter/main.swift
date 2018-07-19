//
//  main.swift
//  PhotoSorter
//
//  Created by Tim Oliver on 17/7/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

import Foundation
import Commander
import PathKit
import ImageIO
import CommonCrypto

// Extend String as an error so we can throw with error strings
extension String: Error {}

// Store a list of file hashes so we can quickly pick redundant files
let hashedFiles = [String]()

// MARK: - Sort -

func sortPhotos(folders: [String], output: String) {
    // Loop through each folder
    for folder in folders {
        let path = Path(folder).absolute().string
        do { try sort(contentsOf: path, output: output) }
        catch { print("\(error)")  }
    }
}

func sort(contentsOf folder: String, output: String) throws {
    // Print that we're starting
    print("Scanning folder: \(folder)... ", terminator: "")
    
    let fileManager = FileManager.default
    
    // Get a list of all files in this directory
    let files = try fileManager.contentsOfDirectory(atPath: folder)
    guard files.count > 0 else {
        throw "No files found."
    }
    
    print("", terminator: "\n")
    
    for file in files {
        // Skip hidden files
        if file.prefix(1) == "." { continue }
        
        // Get absolute path of file
        let filePath = (Path(folder) + Path(file))
        
        // Check if folder is a directory
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: filePath.string, isDirectory: &isDir) && isDir.boolValue {
            do { try sort(contentsOf: filePath.string, output: output) }
            catch { print("\(error)") }
            continue
        }
        
        print("Scanning file: \(file)...", terminator: "")
        
        // See if file is an image
        guard let fileExtension = filePath.extension?.lowercased() else {
            print(" No file extension. Skipping.", terminator: "\n")
            continue
        }
        guard fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png" else {
            print(" Not a supported image. Skipping.", terminator: "\n")
            continue
        }
        
        // File is an image
        
        //See if there is an accompanying MOV file
        let movFilePath = filePath.string.prefix(filePath.string.count - fileExtension.count) + "mov"
        
        let fileURL = URL(fileURLWithPath: filePath.string)
        if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) {
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String : AnyObject]
            if let exifProperties = imageProperties?["{Exif}"] as? [String : AnyObject] {
                print((exifProperties["DateTimeOriginal"] as! String))
            }
        }
        
        print("", terminator: "\n")
    }
}

// https://stackoverflow.com/questions/42934154/how-can-i-hash-a-file-on-ios-using-swift-3
func sha256(url: URL) -> String? {
    do {
        let bufferSize = 1024 * 1024
        // Open file for reading:
        let file = try FileHandle(forReadingFrom: url)
        defer {
            file.closeFile()
        }
        
        // Create and initialize SHA256 context:
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        
        // Read up to `bufferSize` bytes, until EOF is reached, and update SHA256 context:
        while autoreleasepool(invoking: {
            // Read up to `bufferSize` bytes
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_SHA256_Update(&context, $0, numericCast(data.count))
                }
                // Continue
                return true
            } else {
                // End of file
                return false
            }
        }) { }
        
        // Compute the SHA256 digest:
        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_SHA256_Final($0, &context)
        }
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    } catch {
        print(error)
        return nil
    }
}

// MARK: - Main -

command(
    VariadicOption<String>("folder", description: "File path to folder to scan for photos"),
    Option<String>("output", default: "~/Desktop/Photos-Sorted", description: "File path to output folder (Will be created if doesn't exist")
) { folders, output in
    guard folders.count > 0 else {
        print("Please specify one or more folders to scan.")
        return
    }
    
    guard !output.isEmpty else {
        print("Please specify a destination folder.")
        return
    }
    
    sortPhotos(folders: folders, output: output)
}.run()
