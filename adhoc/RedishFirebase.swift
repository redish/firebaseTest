//
//  RedishFirebase.swift
//
//  Created by redish on 2016/07/12.
//  Copyright © 2016 redish. All rights reserved.
//

import Foundation
import Firebase

// Auto同期オブジェクト.
class AutoSync {
    let o:AnyObject ;
    init(_ target:AnyObject) {
        o = target ;
        objc_sync_enter(o) ;
    }
    deinit {
        objc_sync_exit(o) ;
    }
}



// 日付フォーマット変換.
private class DatetimeFormat {
    var formatter = NSDateFormatter()
    
    init() {
        formatter.locale = NSLocale(localeIdentifier: "ja_JP") ;
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" ;
    }
}
private let DatetimeFormat_ = DatetimeFormat()
private func dateString(value:NSDate) -> String {
    return DatetimeFormat_.formatter.stringFromDate( value ) ;
}
private func nowDateString() -> String {
    return dateString(NSDate())
}

// Redish用Firebaseリアルタイムデータベース管理要素.
private class RedishFirebaseElement {
    
    // パス.
    var path:String = ""
    
    // リファレンス.
    var ref:FIRDatabaseReference! = nil
    
    // モニタハンドル.
    var hnd:FIRDatabaseHandle! = nil
}

// Redish用Firebaseリアルタイムデータベース接続コア.
private class RedishFirebaseCore {
    
    // 初期化フラグ.
    private var initFlag = false
    
    // ルートreference.
    private var rootRef:FIRDatabaseReference!
    
    // Firebase初期化.
    private func _create() {
        _ = AutoSync( self ) ;
        if( initFlag ) {
            return
        }
        FIRApp.configure()
        rootRef = FIRDatabase.database().reference()
        initFlag = true
    }
    
    // 指定パスのリファレンス情報を生成.
    func createReference(path:String) -> FIRDatabaseReference! {
        _create()
        return rootRef.child(path)
    }
    
    // 指定リファレンスの監視開始(追加+更新).
    func startMonitor(target:FIRDatabaseReference!, limit:UInt, call: (FIRDataSnapshot!) -> Void) -> FIRDatabaseHandle! {
        _create()
        return target.queryLimitedToLast(limit).observeEventType(.Value, withBlock: { snapshot in
            if self.convertSnapshot(snapshot) != nil {
                print( "##################startMonitor:\(snapshot)")
                call(snapshot)
            }
        })
    }
    
    // 指定リファレンスの監視開始(追加).
    func startMonitorToAdded(target:FIRDatabaseReference!, limit:UInt, call: (FIRDataSnapshot!) -> Void) -> FIRDatabaseHandle! {
        _create()
        return target.queryLimitedToLast(limit).observeEventType(.ChildAdded, withBlock: { snapshot in
            if self.convertSnapshot(snapshot) != nil {
                print( "##################startMonitorToAdded:\(snapshot)")
                call(snapshot)
            }
        })
    }
    
    // 指定リファレンスの監視開始(更新).
    func startMonitorToUpdate(target:FIRDatabaseReference!, limit:UInt, call: (FIRDataSnapshot!) -> Void) -> FIRDatabaseHandle! {
        _create()
        return target.queryLimitedToLast(limit).observeEventType(.ChildChanged, withBlock: { snapshot in
            if self.convertSnapshot(snapshot) != nil {
                print( "##################startMonitorToUpdate:\(snapshot)")
                call(snapshot)
            }
        })
    }
    
    // 指定リファレンスの監視停止.
    func endMonitor(target:FIRDatabaseReference!, hnd:FIRDatabaseHandle!) {
        _create()
        target.removeObserverWithHandle(hnd)
    }
    
    // データ追加.
    func addValue(target:FIRDatabaseReference!, value:Dictionary<String,String!>!) {
        target.childByAutoId().setValue(value)
    }
    
    // データセット.
    func setValue(target:FIRDatabaseReference!, key:String, value:Dictionary<String,String!>!) {
        target.child(key).setValue(value)
    }
    
    // RedishFirebaseElementの生成.
    func createElement(path:String) -> RedishFirebaseElement! {
        
        // 要素作成.
        let e:RedishFirebaseElement! = RedishFirebaseElement()
        e.path = path
        e.ref = createReference(path)
        e.hnd = nil
        return e
    }
    
    // RedishFirebaseElementの破棄.
    func destroyElement(e:RedishFirebaseElement!) {
        if e == nil || e.ref == nil || e.hnd == nil {
            return
        }
        endMonitor(e.ref, hnd: e.hnd)
        e.hnd = nil
    }
    
    // snapshotのNSNull対応.
    private func convertSnapshot( snapshot:FIRDataSnapshot! ) -> FIRDataSnapshot! {
        //print("ノードの値が変わりました！: \(snapshot.value?.description)")
        if ((snapshot.value?.isKindOfClass(NSNull))==true) {
            return nil
        }
        return snapshot
    }
}

// コアメソッド.
private let CORE:RedishFirebaseCore! = RedishFirebaseCore()

// ユーザアプリチャット管理.
class FirebaseByRedishUserApps {
    
    // ユーザID.
    private var userId:Int = -1
    
    // ルームスタッフID.
    private var merchantUserId = -1
    
    // ユーザ情報.
    private var user:RedishFirebaseElement! = nil
    
    // メッセージ群.
    private var messages:RedishFirebaseElement! = nil
    
    // 生成フラグ.
    private var createFlag:Bool = false
    
    // 初期処理.
    func create(id:Int, limit:UInt, call: (FIRDataSnapshot!) -> Void) {
        _ = AutoSync( self )
        destroy()
        
        // 監視領域を作成.
        self.userId = id
        self.user = CORE.createElement("/users/u\(id)/merchant_users/")
        self.user.hnd = CORE.startMonitor(self.user.ref, limit:limit, call:call)
        self.createFlag = true
    }
    
    // 終了化.
    func destroy() {
        _ = AutoSync( self )
        
        var e:RedishFirebaseElement!
        e = self.user
        self.user = nil
        CORE.destroyElement(e)
        
        e = self.messages
        self.messages = nil
        CORE.destroyElement(e)
        
        self.userId = -1
        self.merchantUserId = -1
        self.createFlag = false
    }
    
    // 生成チェック.
    func isCreate() -> Bool {
        _ = AutoSync( self )
        return self.createFlag
    }
    
    // 対象スタッフIDに対して、ルーム作成.
    func createRoom(merchantUserId:Int) {
        _ = AutoSync( self )
        
        let ref = CORE.createReference("/members/")
        let uKey = "u\(self.userId)"
        let muKey = "mu\(merchantUserId)"
        let key = "\(uKey)_\(muKey)"
        
        var value:Dictionary<String,String!> = Dictionary<String,String!>()
        value[uKey] = "true"
        value[muKey] = "true"
        CORE.setValue(ref, key: key, value: value)
    }
    
    // 対象スタッフIDに対して、メッセージ送信.
    func send(merchantUserId:Int, message:String) {
        _ = AutoSync( self )
        
        let uKey = "u\(self.userId)"
        let muKey = "mu\(merchantUserId)"
        let key = "\(uKey)_\(muKey)"
        let now = nowDateString()
        
        // messagesにセット.
        var ref = CORE.createReference("/messages/\(key)/")
        CORE.addValue(ref, value: ["message": message, "sender": uKey, "send_at": now])
        
        // usersにセット.
        ref = CORE.createReference("/users/\(uKey)/merchant_users/")
        CORE.setValue(ref, key:muKey, value:["room": key, "last_update_at": now, "last_message": message])
        
        // merchant_usersにセット.
        ref = CORE.createReference("/merchant_users/\(muKey)/users/")
        CORE.setValue(ref, key:uKey, value:["room": key, "last_update_at": now, "last_message": message])
    }
    
    // 対象スタッフIDのルーム監視開始.
    func startMonitor(merchantUserId:Int, limit:UInt, call: (FIRDataSnapshot!) -> Void) {
        _ = AutoSync( self )
        
        // 別の監視条件が存在する場合は、クリア.
        if self.merchantUserId != -1 {
            if self.merchantUserId != merchantUserId {
                stopMonitor()
            }
            else {
                return;
            }
        }
        
        let uKey = "u\(self.userId)"
        let muKey = "mu\(merchantUserId)"
        let key = "\(uKey)_\(muKey)"
        
        var e:RedishFirebaseElement! = self.messages
        if e == nil {
            e = CORE.createElement("/messages/\(key)/")
            self.messages = e
        }
        
        // 監視開始.
        e.hnd = CORE.startMonitorToAdded(e.ref,limit: limit, call: call)
        self.merchantUserId = merchantUserId
    }
    
    // 対象スタッフIDのルーム監視終了.
    func stopMonitor() {
        _ = AutoSync( self )
        
        let e:RedishFirebaseElement! = self.messages
        self.messages = nil
        CORE.destroyElement(e)
        self.merchantUserId = -1
    }
}


