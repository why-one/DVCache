//
//  DVKVStorage.swift
//  DVCache
//
//  Created by David on 2019/2/26.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import Foundation

enum DVKVStorageType {
    // the 'value' is stored as a file in file system
    case file
    // the 'value' is stored in sqlite with blob type
    case sqlite
    // the 'value' is stored in file system or sqlite based on your choice.
    case mixed
}

class DVKVStorage: NSObject {
    
    
    
}
