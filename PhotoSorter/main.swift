//
//  main.swift
//  PhotoSorter
//
//  Created by Tim Oliver on 17/7/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

import Foundation
import Commander

command(
    Option("name", default: "world"),
    Option("count", default: 1, description: "The number of times to print.")
) { name, count in
    for _ in 0..<count {
        print("Hello \(name)")
    }
}.run()
