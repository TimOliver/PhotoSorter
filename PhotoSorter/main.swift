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

// Extend String as an error so we can throw with error strings
extension String: Error {}

// Store a list of file hashes so we can quickly pick redundant files
let hashedFiles = [String]()

// MARK: - Sort -

func sortPhotos(folders: [String], output: String) {
    print("Outputting to \(output)")
    
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
        guard fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png" || fileExtension == "heic" || fileExtension == "dng" else {
            print(" Not a supported image. Skipping.", terminator: "\n")
            continue
        }
        
        // Check if we can open as an image
        guard let imageSource = CGImageSourceCreateWithURL(filePath.url as CFURL, nil) else {
            print(" Unable to load image data. Skipping.", terminator: "\n")
            continue
        }

        // Load out the properties associated with this image
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String : AnyObject] else {
            print(" Unable to access image properties. Skipping.", terminator: "\n")
            continue
        }
        
        // Extract the EXIF data
        guard let exifProperties = imageProperties["{Exif}"] as? [String : AnyObject] else {
            print(" No EXIF data. Skipping.", terminator: "\n")
            continue
        }
        
        // Extract the date time from the EXIF
        guard let dateTime = exifProperties["DateTimeOriginal"] as? String else {
            print(" No timestamp in EXIF data. Skipping.", terminator: "\n")
            continue
        }
        
        // The date format looks like 2014:09:29 08:36:47
        
        // Split up the string to capture the components
        let dateTimeParts = dateTime.split(separator: ":")
        guard dateTimeParts.count > 2 else {
            print(" Date invalid. Skipping.", terminator: "\n")
            continue
        }
        
        // Get month and year
        let year = dateTimeParts[0]
        let month = dateTimeParts[1]
        
        // Make sure we actually got date data from it
        guard Int(year) != nil && Int(month) != nil else {
            print(" Can't find date data. Skipping.", terminator: "\n")
            continue
        }

        // Create folder structer
        let outputPath = Path(output) + Path(String(year)) + Path(String(month))
        if !fileManager.fileExists(atPath: outputPath.string) {
            try! fileManager.createDirectory(atPath: outputPath.string, withIntermediateDirectories: true, attributes: nil)
        }
        
        var destinationPath = outputPath + Path(file)
        var newFileName = String(file.split(separator: ".")[0])
        
        // Check if the file already exists there
        if fileManager.fileExists(atPath: destinationPath.string) {
            let sourceHash = md5(fileURL: filePath.url)
            let destHash = md5(fileURL: destinationPath.url)
            
            if sourceHash == destHash {
                print(" File already exists. Skipping.", terminator: "\n")
                continue
            }
            
            let pathExtension = destinationPath.url.pathExtension
            
            var i = 1
            repeat {
                newFileName = String(file.split(separator: ".")[0])
                newFileName += "-\(i)"
                i = i + 1
                destinationPath = outputPath + Path(newFileName + ".\(pathExtension)")
            } while fileManager.fileExists(atPath: destinationPath.string)
        }
        
        print(" Copying...", terminator: "")
        
        //Copy the file over to the destination
        try! fileManager.moveItem(at: filePath.url, to: destinationPath.url)
        
        //See if there is an accompanying MOV file (For Live Photos) we also need to move
        let movieFileName = String(file.split(separator: ".")[0]) + ".mov"
        let movieFilePath = Path(folder) + Path(movieFileName)
        if fileManager.fileExists(atPath: movieFilePath.string) {
            let newMovieFilePath = outputPath + (newFileName + ".mov")
            try! fileManager.moveItem(at: movieFilePath.url, to: newMovieFilePath.url)
        }
        
        //See if there is an accompanying AAE file (For metadata) we also need to move
        let metaFileName = String(file.split(separator: ".")[0]) + ".aae"
        let metaFilePath = Path(folder) + Path(metaFileName)
        if fileManager.fileExists(atPath: metaFilePath.string) {
            let newMetaFilePath = outputPath + (newFileName + ".aae")
            try! fileManager.moveItem(at: metaFilePath.url, to: newMetaFilePath.url)
        }
        
        print(" Done!", terminator: "\n")
    }
}

// https://stackoverflow.com/questions/38097710/swift-3-changes-for-getbytes-method
func md5(fileURL: URL) -> String {
    
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    let data = try! Data(contentsOf: fileURL)
    CC_MD5([UInt8](data), CC_LONG(data.count), &digest)
    
    var digestHex = ""
    for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
    }
    
    return digestHex
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
