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

extension String: Error {}

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
    print("Scanning \(folder)... ", terminator: "")
    
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
        let filePath = (Path(folder) + Path(file)).string
        
        // Check if folder is a directory
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: filePath, isDirectory: &isDir) && isDir.boolValue {
            do { try sort(contentsOf: filePath, output: output) }
            catch { print("\(error)") }
            continue
        }
        
        // See if file is a JPEG
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
