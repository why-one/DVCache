//
//  DVDiskCache.swift
//  DVCache
//
//  Created by David on 2019/2/25.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import UIKit

class DVDiskCache {
    
    static var globalInstancesLock:NSLock = NSLock()
    static var globalInstances:[String:AnyObject?] = [:]
    
    fileprivate static func diskCacheGetGlobal(path:String?)->DVDiskCache? {
        guard let localPath = path else { return nil }
        globalInstancesLock.lock()
        let cache = globalInstances[localPath]?.flatMap({$0}) as? DVDiskCache
        globalInstancesLock.unlock()
        return cache
    }
    
    convenience init?() {
        self.init(path: "", inlineThreshold: 0)
    }
    
    convenience init?(path:String) {
        self.init(path: path, inlineThreshold: 1024*20)
    }
    
    init?(path:String,inlineThreshold:Int) {
        let globalCache = DVDiskCache.diskCacheGetGlobal(path: path)
        guard let cache = globalCache else { return nil }
        
    }
    
    func containsObjectForKey(key:String)->Bool {
       return false
    }
    
    func containsObjectForKey(key:String,block:(_ key:String,_ contains:Bool)->Void?) {
        
    }
    
    func objectForKey(key:String)->AnyObject? {
        return nil
    }
    
    func objectForKey(key:String,block:(_ key:String,_ object:AnyObject)->Void) {
        
    }
    
    func setObjectForKey(objc:AnyObject,key:String) {
        
    }
    
    func setObjectForKey(objc:AnyObject,key:String,block:()->()?) {
        
    }
    
    func removeObjectForKey(key:String) {
        
    }
    
    func removeObjectForKey(key:String,block:(_ key:String)->()?) {
        
    }
    
    func removeAllObjects() {
        
    }
    
    func removeAllObjectsWithBlock(block:()->()?) {
        
    }
    
    func removeAllObjectsWithProgressBlock(progress:(_ removedCount:Int,_ totalCount:Int)->()?,endBlock:(_ hasError:Bool)->()?) {
        
    }
}
