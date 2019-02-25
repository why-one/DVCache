//
//  DVMemoryCache.swift
//  DVCache
//
//  Created by David on 2019/2/25.
//  Copyright © 2019年 WHYIOS. All rights reserved.
//

import UIKit

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
