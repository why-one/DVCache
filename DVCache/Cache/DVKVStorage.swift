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

// 数据存储的结点
struct DVKVStoreageItem {
    
    var key:String         ///< key
    var value:Data?         ///< value
    var filename:String?   ///< 文件名
    var size:Int           ///< value的大小
    var modTime:Int        ///< timestamp
    var accessTime:Int     ///< last access unix timestamp
    var extendData:Data?   ///< 附加数据
}

class DVKVStorage:NSObject {
    
    let type:DVKVStorageType
    
    init?(path:String,type:DVKVStorageType) {
        self.type = type
        super.init()
    }
    
    static func setExtendedData(data:Data,objc:AnyObject?){
        
    }
    
    static func objcGetExtendData(objc:AnyObject?)->Data? {
        return nil
    }
    
    // 删除元素数量到maxSize
    func removeItemsToFitSize(maxSize:UInt) {
        
    }
    
    func removeItemsToFitCount(maxSize:UInt) {
        
    }
    
    func removeAllItems() {
        
    }
    
    func removeItemsEarLierThan(age:Double) {
        
    }
    
    func removeItemForKey(key:String) {
        
    }
    
    func getItemSize() -> Int64 {
        return 0
    }
    
    func itemExistsForKey(key:String?) -> Bool {
        return false
    }
    
    func getItemForKey(key:String) -> DVKVStoreageItem? {
        return nil
    }
    
    func saveItemWithKey(key:String,obj:Data?,fileName:String?,extendData:Data?) {
        
    }
    
    func removeAllObjectsWithProgressBlock(progress:(_ removedCount:Int,_ totalCount:Int)->()?,endBlock:(_ hasError:Bool)->()?) {
        
    }
    
    func getItemsCount() -> UInt {
        return 0
    }
}
