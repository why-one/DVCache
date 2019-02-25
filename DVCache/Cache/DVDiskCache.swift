//
//  DVDiskCache.swift
//  DVCache
//
//  Created by David on 2019/2/25.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import UIKit

class DVDiskCache {

    init?(path:String) {
        
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
