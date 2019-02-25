//
//  DVMemoryCache.swift
//  DVCache
//
//  Created by David on 2019/2/25.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import UIKit


fileprivate class DVLinkedNode:Equatable {
    
    var prev:DVLinkedNode?
    var next:DVLinkedNode?
    
    var key:String?
    var value:AnyObject?
    var cost:Int = 0
    var time:Int = 0
}

fileprivate func ==(node1:DVLinkedNode,node2:DVLinkedNode) -> Bool {
    return node1.key == node2.key
}

// design the struct to save Data effective
fileprivate class DVLinkedMap:NSObject {
    
    var dic:[String?:AnyObject?]
    var totalCost:Int
    var totalCount:Int
    var header:DVLinkedNode?
    var footer:DVLinkedNode?
    var releaseOnMainThread:Bool
    var releaseAsynchronously:Bool
    
    override init() {
        dic = [:]
        releaseOnMainThread = false
        releaseAsynchronously = true
        totalCost = 0
        totalCount = 0
    }
    // insert node into header and update the cost
    func insertNodeAtHead(node:DVLinkedNode?) {
        guard node != nil else { return }
        if header == nil {
            header = node
            footer = node
        } else {
            node?.next = header
            header?.prev = node
            header = node
        }
        totalCost = totalCost + (node?.cost ?? 0)
        totalCount = totalCount + 1
        dic[node?.key] = node
    }
    // bring already exists node to header
    func bringNodeToHead(node:DVLinkedNode?) {
        guard  node != nil else { return }
        if header == nil {  header = node; footer = node}
        if header == node { return }
        // 1.node为header 2.node为footer 3.均不是
        if node == footer {
            footer = node?.prev
            footer?.next = nil
        } else {
            node?.next?.prev = node?.prev
            node?.prev?.next = node?.next
        }
        node?.next = header
        node?.prev = nil
        header?.prev = node
        header = node
    }
    // remove node and update cost
    func removeNode(node:DVLinkedNode?) {
        guard let localNode = node else { return }
        // 1.header 2.footer 3.other
        if  node == header {
            header = node?.next   //必须先赋值,如果先清空的话node就是nil了
            header?.prev = nil
        } else if node == footer {
            footer = node?.prev   // 必须先赋值,如果先清空的话node就是nil了
            footer?.next = nil
        } else {
            node?.next?.prev = node?.prev
            node?.prev?.next = node?.next
        }
        totalCount -= 1
        totalCost -= localNode.cost
        dic[node?.key] = nil
    }
    // remove footer is exists and update cost
    func removeFooter()->DVLinkedNode? {
        // 1.header == footer 2. footer
        if header == footer {
            header = nil
            footer = nil
        } else {
            footer = footer?.prev
            footer?.next = nil
        }
        totalCount -= 1
        totalCost -= (footer?.cost ?? 0)
        dic[footer?.key] = nil
        return footer
    }
    // remove all in background queue
    func removeAll() {
        // 1.清除hash 2. 清除链表 3.cost/total归0
//        dic = [:]
//        while header?.next != nil {
//            let node = header
//            header = nil
//            header = node?.next
//        }
        totalCount = 0
        totalCost = 0
        //
        header = nil
        footer = nil
        if (releaseAsynchronously) {
            DispatchQueue.main.async {
                self.dic = [:]
            }
        } else if (releaseOnMainThread) {
            DispatchQueue.global().async {
                self.dic = [:]
            }
        } else {
            self.dic = [:]
        }
    }
}


class DVMemoryCache:NSObject {
    
    var name:String?
    let lock:NSLock
    fileprivate let lru:DVLinkedMap
    fileprivate let queue:DispatchQueue
    fileprivate let autoTrimInterval:Int
    fileprivate let shouldRemoveAllObjectsOnMemoryWarning:Bool
    fileprivate let shouldRemoveAllObjectsWhenEnteringBackground:Bool
    var countLimit:Int
    var costLimit:Int
    var ageLimit:Int
    var didReceiveWarningBlock:((_ cache:DVMemoryCache)->())?
    var didEnterBackgroundBlock:((_ cache:DVMemoryCache)->())?
    
    var totalCount:Int {
        lock.lock()
        let totalCount = lru.totalCount
        lock.unlock()
        return totalCount
    }
    
    var totalCost:Int {
        lock.lock()
        let totalCost = lru.totalCost
        lock.unlock()
        return totalCost
    }
    
    var releaseOnMainThread:Bool {
        lock.lock()
        let releaseOnMainThread = lru.releaseOnMainThread
        lock.unlock()
        return releaseOnMainThread
    }
    
    func setReleaseOnMainThread(realseOnMainThread:Bool) {
        lock.lock()
        lru.releaseOnMainThread = releaseOnMainThread
        lock.unlock()
    }
    
    var releaseAsynchronously:Bool {
        lock.lock()
        let releaseOnMainThread = lru.releaseAsynchronously
        lock.unlock()
        return releaseOnMainThread
    }
    
    func setReleaseAsynchronously(releaseAsynchronously:Bool) {
        lock.lock()
        lru.releaseAsynchronously = releaseAsynchronously
        lock.unlock()
    }
    
    override init() {
        lock = NSLock()
        lru = DVLinkedMap()
        queue = DispatchQueue.init(label: "com.whyiOS.cache.memory")
        countLimit = Int.max
        costLimit = Int.max
        ageLimit = Int.max
        autoTrimInterval = 5
        shouldRemoveAllObjectsOnMemoryWarning = true
        shouldRemoveAllObjectsWhenEnteringBackground = true
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        self.trimRecursively()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.lru.removeAll()
    }
    
// NSNotificationCenter
    @objc func appDidReceiveMemoryWarningNotification() {
        didReceiveWarningBlock?(self)
        guard shouldRemoveAllObjectsOnMemoryWarning else {
             return
        }
        removeAllObjects()
    }
    
    @objc func appDidEnterBackgroundNotification() {
       didEnterBackgroundBlock?(self)
        guard shouldRemoveAllObjectsWhenEnteringBackground else {
            return
        }
        removeAllObjects()
    }
    
    fileprivate func trimRecursively() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {[weak self] in
            self?.trimRecursively()
            self?.trimInBackground()
        }
    }
    fileprivate func trimInBackground() {
        queue.async {[weak self] in
            self?.trimToCost(costLimit: self?.costLimit ?? 0)
            self?.trimToCount(count: self?.countLimit ?? 0)
            self?.trimToAge(age: self?.ageLimit ?? 0)
        }
    }
    
    func trimToCost(costLimit:Int) {
        // 1. 判断costLimit是否为0 2.costLimit大于限制均完成 3.始终删除tail并且往Array中插入 4.在主线程移除数据
        var finish = false
        lock.lock()
        if costLimit == 0 {
            lru.removeAll()
            finish = true
        } else if lru.totalCost < costLimit {
            finish = true
        }
        lock.unlock()
        if finish {return}
        var nodes = [DVLinkedNode?]()
        while !finish {
            lock.lock()
            if lru.totalCost > costLimit {
                let node = lru.removeFooter()
                nodes.append(node)
            } else {
                finish = true
            }
            lock.unlock()
        }
        let queue = lru.releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global()
        // 让nodes在这个线程释放
        queue.async {
            print(nodes.count)
        }
    }
    
    func trimToCount(count:Int) {
        // 1. 判断countLimit是否为0 2.countLimit大于限制均完成 3.始终删除tail并且往Array中插入 4.在主线程移除数据
        var finish = false
        lock.lock()
        if count == 0 {
            lru.removeAll()
            finish = true
        } else if lru.totalCount < count {
            finish = true
        }
        lock.unlock()
        if finish {return}
        var nodes = [DVLinkedNode?]()
        while !finish {
             lock.lock()
            if lru.totalCount > count {
                let node = lru.removeFooter()
                nodes.append(node)
            } else {
                finish = true
            }
            lock.unlock()
        }
        let queue = lru.releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global()
        // 让nodes在这个线程释放
        queue.async {
            print(nodes.count)
        }
    }
    
    func trimToAge(age:Int) {
        // 1.age是否小于等于0 2.是否限制大于footer的时间 3.循环删除,如果当前时间减去 那个时间戳 如果大于值则一直加 4.GCD线程移除arrays
        var finish = false
        let now = CACurrentMediaTime()
        lock.lock()
        if age <= 0 {
            lru.removeAll()
            finish = true
        } else if lru.footer == nil || Int((now) - (Double)(lru.footer?.time ?? 0)) < age {
            finish = true
        }
        lock.unlock()
        if finish {return}
        var nodes = [DVLinkedNode?]()
        while !finish {
            lock.lock()
            if Int((now) - (Double)(lru.footer?.time ?? 0)) > age {
                let node = lru.removeFooter()
                nodes.append(node)
            }else {
                finish = true
            }
            lock.unlock()
        }
        let queue = lru.releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global()
        // 让nodes在这个线程释放
        queue.async {
            print(nodes.count)
        }
    }
    
    func containsObjectForKey(key:String)->Bool {
        lock.lock()
        let hasNode = lru.dic.contains(where: {($0.key ?? "") == key})
        lock.unlock()
        return hasNode
    }
    // 1. dic中查询 2.更新node中的time 3.移动到最前面,因为加入的时候按照时间戳排序了 4.取出node中的value
    func objectForKey(key:String)->AnyObject? {
        lock.lock()
        let node = lru.dic[key]?.flatMap({$0})
        guard let localNode = node as? DVLinkedNode else {
            lock.unlock()
            return nil
        }
        localNode.time = (Int)(CACurrentMediaTime())
        lru.bringNodeToHead(node: localNode)
        lock.unlock()
        return localNode.value
    }
    
    func setObjectForKey(objc:AnyObject,key:String) {
        setObjectForKey(objc: objc, key: key, cost: 0)
    }
    
    func setObjectForKey(objc:AnyObject?,key:String,cost:Int) {
        // 1.如果objc为nil则根据key删除 2.从dic中根据key拿到item 3.如果item存在,更新lru的cost,更新item的time,cost,objc移动到头部 4.如果不存在的话,则time,key,value,插入到头部  5.如果cost超了，递归删除 6.如果count超了,则删除.然后追加到array中,最后在特定的队列移除
        guard objc != nil else {
            removeObjectForKey(key: key)
            return
        }
        lock.lock()
        let node = lru.dic[key]?.flatMap({$0})
        let time = (Int)(CACurrentMediaTime())
        if let localNode = node as? DVLinkedNode {
            lru.totalCost -= cost
            localNode.cost = cost
            lru.totalCost += cost
            localNode.time = time
            localNode.value = objc
            lru.bringNodeToHead(node: localNode)
        } else {
            let item = DVLinkedNode()
            item.cost = cost
            item.key = key
            item.value = objc
            item.time = time
            lru.insertNodeAtHead(node: item)
        }
        if lru.totalCost > costLimit {
            queue.async {[weak self] in
                self?.trimRecursively()
            }
        }
        var nodes = [DVLinkedNode?]()
        if lru.totalCount > countLimit {
            let node = lru.removeFooter()
            nodes.append(node)
            let queue = lru.releaseOnMainThread ? DispatchQueue.main : DispatchQueue.global()
            // 让nodes在这个线程释放
            queue.async {
                print(nodes.count)
            }
        }
        lock.unlock()
    }
    
    func removeObjectForKey(key:String) {
        
    }
    
    func removeAllObjects() {
        lock.lock()
        lru.removeAll()
        lock.unlock()
    }
}
