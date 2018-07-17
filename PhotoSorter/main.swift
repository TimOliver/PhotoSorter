//
//  main.swift
//  PhotoSorter
//
//  Created by Tim Oliver on 17/7/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

import Foundation
import Commander
import ImageIO

// MARK: - Sort -

func sortPhotos(folders: [String], output: String) {
    
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
