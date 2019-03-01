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
    // 存储器
    let kv:DVKVStorage
    let path:String          // 路径
    let lock:NSLock          // 锁
    let queue:DispatchQueue  // 队列
    let inlineThreshold:UInt // 限制
    var countLimit:UInt      // 数量限制
    var costLimit:UInt       // 消耗限制
    var ageLimit:Double      // age限制
    var freeDiskSpaceLimit:Double   // 磁盘限制
    var autoTrimInterval:UInt64 // auto trim
    
    var customUnarchiveBlock:((_ data:Data?)->AnyObject)?  /// < 通过数据解码
    var customArchiveBlock:((_ objc:AnyObject?)->Data?)?     /// < 通过数据编码
    
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
    
    init?(path:String,inlineThreshold:UInt) {
//        let globalCache = DVDiskCache.diskCacheGetGlobal(path: path)
//        if globalCache != nil {return}
        var type = DVKVStorageType.sqlite
        if inlineThreshold == 0 {
            type = .file
        } else if inlineThreshold == UInt.max {
            type = .sqlite
        } else {
            type = .mixed
        }
        let kv = DVKVStorage(path: path, type: type)
        guard let localKV = kv else { return nil}
        self.kv = localKV
        self.path = path
        self.lock = NSLock()
        self.queue = DispatchQueue(label: "com.david.cache.disk")
        self.inlineThreshold = inlineThreshold
        self.countLimit = UInt.max
        self.costLimit = UInt.max
        self.ageLimit = Double.infinity
        self.freeDiskSpaceLimit = 0
        self.autoTrimInterval = 60
        
        return nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func trimRecursively() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self]  in
            self?.trimInBackground()
            self?.trimRecursively()
        }
    }
    
    private func trimInBackground() {
        queue.async {[weak self]  in
            guard let _self = self else {
                return
            }
            _self.lock.lock()
            _self.trimToCost(costLimit: _self.costLimit)
            _self.trimToCount(countLimit: _self.countLimit)
            _self.trimToAge(ageLimit: _self.ageLimit)
            _self.trimToFreeDiskSpace(freeDiskSpaceLimit: _self.freeDiskSpaceLimit)
            _self.lock.unlock()
        }
    }
    
    private func trimToCost(costLimit:UInt) {
        kv.removeItemsToFitSize(maxSize: costLimit)
    }
    
    private func trimToCount(countLimit:UInt) {
        kv.removeItemsToFitCount(maxSize: countLimit)
    }
    
    private func trimToAge(ageLimit:Double) {
        // 1.如果ageLimit <= 0 直接全局删除 return  2.如果传入的时间戳大于当前时间则直接返回.不需要做任何事  3.当前时间-限制时间大于 Max return 4.删到位
        if ageLimit <= 0 {
            kv.removeAllItems()
            return
        }
        let timeStamp =  time(nil)
        if (timeStamp <= Int(ageLimit)) {
            return;
        }
        let timeGap = (Double)(timeStamp) - ageLimit
        if timeGap >= Double.infinity {
            return
        }
        kv.removeItemsEarLierThan(age: timeGap)
    }
    
    private func trimToFreeDiskSpace(freeDiskSpaceLimit:Double) {
        
    }
    
    func containsObjectForKey(key:String)->Bool {
       lock.lock()
       let contains = kv.itemExistsForKey(key: key)
       lock.unlock()
       return contains
    }
    
    func containsObjectForKey(key:String,block:@escaping (_ key:String,_ contains:Bool)->Void?) {
        queue.async {[weak self] in
            let contains = self?.kv.itemExistsForKey(key: key) ?? false
            block(key,contains)
        }
    }
    
    func objectForKey(key:String)->AnyObject? {
        //1.通过key得到item 2.item不存在直接return 3.item的value为空直接return 4.对object进行解析拿到AnyObject 5.如果数据存在而且额外数据存在则设置数据到DiskCache
        guard let kvstormItem = kv.getItemForKey(key: key) else {return nil}
        guard let data = kvstormItem.value else {return nil}
        var objc = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? AnyObject)?.flatMap({$0})
        // 如果外界传入了解码器则根据外界的解码器进行解码
        if let archiveBlock = customUnarchiveBlock {
            objc = archiveBlock(data)
        }
        guard let extData = kvstormItem.extendData,let localObjc = objc else {
            return  objc
        }
        DVKVStorage.setExtendedData(data: extData, objc: localObjc)
        return localObjc
    }
    
    func objectForKey(key:String,block:((_ key:String,_ object:AnyObject?)->Void)?) {
        queue.async { [weak self] in
            let obj = self?.objectForKey(key: key)
            block?(key,obj)
        }
    }
    
    func setObjectForKey(objc:AnyObject?,key:String?) {
        // 1.判断key是否为空,如果为空则直接return 2.objc是否为空,如果objc为空则根据key移除元素 3.根据objc获取extendData。 4. 如果编码器存在则根据编码器对传入的objc进行编码 5.如果编码器不存在则利用系统的编码器进行编码 5.5 获取fileName 6.通过kv进行存储
        guard let localKey = key else { return  }
        guard let localObjc = objc else { return kv.removeItemForKey(key: localKey) }
        // extendData
        let extendData = DVKVStorage.objcGetExtendData(objc: localObjc)
        var saveData:Data?
        if let customArchiveBlock = customArchiveBlock {
            saveData = customArchiveBlock(objc)
        } else{
            saveData = try? JSONSerialization.data(withJSONObject: objc as Any, options: .prettyPrinted)
        }
        var fileName:String?
        if kv.type != .sqlite {
            if (saveData?.count ?? 0) > inlineThreshold {
                fileName = fileNameForKey(key: localKey)
            }
        }
        lock.lock()
        kv.saveItemWithKey(key: localKey, obj: saveData, fileName: fileName, extendData: extendData)
    }
    
    func setObjectForKey(objc:AnyObject,key:String,block:@escaping ()->()?) {
        queue.async {[weak self] in
            self?.setObjectForKey(objc: objc, key: key)
            block()
        }
    }
    
    func removeObjectForKey(key:String) {
        lock.lock()
        kv.removeItemForKey(key: key)
        lock.unlock()
    }
    
    func removeObjectForKey(key:String,block:@escaping (_ key:String)->()?) {
        queue.async {[weak self] in
            self?.kv.removeItemForKey(key: key)
            block(key)
        }
    }
    
    func removeAllObjects() {
        lock.lock()
        kv.removeAllItems()
        lock.unlock()
    }
    
    func removeAllObjectsWithBlock(block:@escaping ()->()?) {
        queue.async {[weak self] in
            self?.removeAllObjects()
            block()
        }
    }
    
    func removeAllObjectsWithProgressBlock(progress:@escaping (_ removedCount:Int,_ totalCount:Int)->()?,endBlock:@escaping (_ hasError:Bool)->()?) {
        queue.async { [weak self]  in
            self?.lock.lock()
            self?.kv.removeAllObjectsWithProgressBlock(progress: progress, endBlock: endBlock)
            self?.lock.unlock()
        }
    }
    
    func fileNameForKey(key:String) -> String? {
        return ""
    }
    
    func totalCount() -> UInt {
        lock.lock()
        let count = kv.getItemsCount()
        lock.unlock()
        return count
    }
    
    
}
