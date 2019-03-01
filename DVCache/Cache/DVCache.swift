//
//  DVCache.swift
//  DVCache
//
//  Created by David on 2019/2/25.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import Foundation

class DVCache:CustomDebugStringConvertible {
    
    // DB name
    fileprivate let name:String
    fileprivate let diskCache:DVDiskCache
    fileprivate let memoryCache:DVMemoryCache
    
    convenience init?() {
        print("Use \"initWithName\" or \"initWithPath\" to create YYCache instance.")
        self.init(path: "")
    }
    
    // convenience构造
    convenience init?(name:String?) {
        guard let name = name else {
            return nil
        }
       let cacheFolder =  NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
       let path = cacheFolder ?? "" + "/\(name)"
       self.init(path: path)
    }
    
    init?(path:String) {
        let localDiskCache = DVDiskCache.init(path: path)
        guard let diskCache = localDiskCache else { return nil }
        let memoryCache = DVMemoryCache.init()
        memoryCache.name = (path as NSString).lastPathComponent
        
        self.name = path
        self.diskCache = diskCache
        self.memoryCache = memoryCache
    }
    
    func containsObjectForKey(key:String)->Bool {
        return memoryCache.containsObjectForKey(key:key) ||   diskCache.containsObjectForKey(key:key)
    }
    
    func containsObjectForKey(key:String,block:@escaping (_ key:String,_ contains:Bool)->Void?) {
        
        if memoryCache.containsObjectForKey(key: key) {
            DispatchQueue.global().async {
                block(key,true)
            }
        } else {
           diskCache.containsObjectForKey(key: key, block: block)
        }
    }
    
    func objectForKey(key:String)->AnyObject? {
        var object = memoryCache.objectForKey(key: key)
//      not cache in memoryCache
        if object == nil {
           object = diskCache.objectForKey(key: key)
            if let objc = object {
                memoryCache.setObjectForKey(objc: objc, key: key)
            }
        }
        return object
    }
    
    func objectForKey(key:String,block:@escaping (_ key:String,_ object:AnyObject?)->Void?) {
        let localObject = memoryCache.objectForKey(key: key)
        if let object = localObject {
            DispatchQueue.global().async {
                block(key,object)
            }
        } else {
            diskCache.objectForKey(key: key) {[weak self] (key, objc) in
                if !(self?.memoryCache.containsObjectForKey(key: key) ?? false) {
                    self?.memoryCache.setObjectForKey(objc: objc, key: key)
                }
                block(key,objc)
            }
        }
    }
    
    func setObject(_ object:AnyObject,_ key:String) {
        memoryCache.setObjectForKey(objc: object, key: key)
        diskCache.setObjectForKey(objc: object, key: key)
    }
    
    func setObject(_ object:AnyObject,_ key:String,block:@escaping ()->()?) {
        memoryCache.setObjectForKey(objc: object, key: key)
        diskCache.setObjectForKey(objc: object, key: key, block: block)
    }
    
    func removeObjectForKey(key:String) {
        memoryCache.removeObjectForKey(key: key)
        diskCache.removeObjectForKey(key: key)
    }
    
    func removeObjectForKey(key:String,block:@escaping (_ key:String)->()?) {
         memoryCache.removeObjectForKey(key: key)
         diskCache.removeObjectForKey(key: key, block: block)
    }
    
    func removeAllObjects() {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects()
    }
    
    func removeAllObjectsWithBlock(block:@escaping ()->()?) {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjectsWithBlock(block: block)
    }
    
    func removeAllObjectsWithProgressBlock(progress:@escaping (_ removedCount:Int,_ totalCount:Int)->()?,endBlock:@escaping (_ hasError:Bool)->()?) {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjectsWithProgressBlock(progress: progress, endBlock: endBlock)
    }
    
    var debugDescription: String {
        return "Class:\(self),name:\(name)"
    }
}


