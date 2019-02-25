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
    
    func containsObjectForKey(key:String)->Bool {
        return false
    }
    
    func containsObjectForKey(key:String,block:(_ key:String,_ contains:Bool)->Void) {
        
    }
    
    func objectForKey(key:String)->AnyObject? {
        return nil
    }
    
    func setObjectForKey(objc:AnyObject,key:String) {
        
    }
    
    func removeObjectForKey(key:String) {
        
    }
    
    func removeAllObjects() {
        
    }
}
