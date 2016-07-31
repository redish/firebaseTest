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
            if self.notEmpty(snapshot) != nil {
                call(snapshot)
            }
        })
    }
    
    // 指定リファレンスの監視開始(追加).
    func startMonitorToAdded(target:FIRDatabaseReference!, limit:UInt, call: (FIRDataSnapshot!) -> Void) -> FIRDatabaseHandle! {
        _create()
        return target.queryLimitedToLast(limit).observeEventType(.ChildAdded, withBlock: { snapshot in
            if self.notEmpty(snapshot) != nil {
                call(snapshot)
            }
        })
    }
    
    // 指定リファレンスの監視開始(更新).
    func startMonitorToUpdate(target:FIRDatabaseReference!, limit:UInt, call: (FIRDataSnapshot!) -> Void) -> FIRDatabaseHandle! {
        _create()
        return target.queryLimitedToLast(limit).observeEventType(.ChildChanged, withBlock: { snapshot in
            if self.notEmpty(snapshot) != nil {
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
    func addValue(target:FIRDatabaseReference!, value:Dictionary<String,AnyObject!>!) {
        target.childByAutoId().setValue(value)
    }
    
    // データセット.
    func setValue(target:FIRDatabaseReference!, key:String, value:Dictionary<String,AnyObject!>!) {
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
    
    // トランザクションによる、データ更新.
    func updateValue(ref:FIRDatabaseReference!, values:[String: AnyObject]) {
        ref.runTransactionBlock({ (currentData:FIRMutableData!) -> FIRTransactionResult in
            var targetData = [String: AnyObject]()
            if currentData.hasChildren() {
                targetData = currentData.value as! [String: AnyObject]
            }
            for (k,v) in values {
                targetData[k] = v
            }
            currentData.value = targetData
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    // トランザクションによる、データ更新.
    func updateValueAndAddCount(ref:FIRDatabaseReference!, target:String, values:[String: AnyObject]) {
        ref.runTransactionBlock({ (currentData:FIRMutableData!) -> FIRTransactionResult in
            // データセット.
            var targetData = [String: AnyObject]()
            if currentData.hasChildren() {
                targetData = currentData.value as! [String: AnyObject]
            }
            for (k,v) in values {
                targetData[k] = v
            }
            // カウントを追加.
            let value = targetData[target]
            if value == nil {
                targetData[target] = 1
            }
            else {
                targetData[target] = 1 + Int(value!.description)!
            }
            currentData.value = targetData
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    // snapshotのNSNull対応.
    private func notEmpty( snapshot:FIRDataSnapshot! ) -> FIRDataSnapshot! {
        if ((snapshot.value?.isKindOfClass(NSNull))==true) {
            return nil
        }
        return snapshot
    }
}

// コアメソッド.
private let CORE:RedishFirebaseCore! = RedishFirebaseCore()

// ルーム情報キャッシュ.
class FirebaseRoomCache {
    private var cache:Array<Dictionary<String,AnyObject!>> = Array<Dictionary<String,AnyObject!>>()
    
    // ルームデータを破棄.
    func clear() {
        _ = AutoSync( self )
        self.cache = Array<Dictionary<String,AnyObject!>>()
    }
    
    // ルームデータ全体を取得.
    func roomValues() -> Array<Dictionary<String,AnyObject!>> {
        _ = AutoSync( self )
        return self.cache
    }
    
    // ルームリストを取得.
    func roomList() -> Array<String> {
        _ = AutoSync( self )
        var ret:Array<String> = Array<String>() ;
        let c = self.cache
        let len = c.count
        for var i = 0 ; i < len ; i++ {
            ret[i] = c[i]["room"]! as! String
        }
        return ret
    }
    
    // ルーム数を取得.
    func roomCount() -> Int {
        _ = AutoSync( self )
        return self.cache.count
    }
    
    // 指定ルームの情報を取得.
    func get(room:String) -> Dictionary<String,AnyObject!>! {
        _ = AutoSync( self )
        let p:Int = searchRoom(room)
        if p == -1 {
            return nil
        }
        return self.cache[p]
    }
    
    // 指定ルームの情報を削除.
    func remove(room:String) -> Bool {
        _ = AutoSync( self )
        let p:Int = searchRoom(room)
        if p == -1 {
            return false
        }
        self.cache.removeAtIndex(p)
        return true
    }
    
    // 指定ルーム名の位置を検索.
    private func searchRoom(room:String) -> Int {
        let c = self.cache
        let len = c.count
        for var i = 0 ; i < len ; i++ {
            if c[i]["room"]! as! String == room {
                return i
            }
        }
        return -1
    }
    
    // データをセット.
    func update(max:Int!, values:NSDictionary!) {
        _ = AutoSync( self )
        if values == nil {
            return
        }
        // 追加先の領域は新たに作成し直す.
        var c:Array<Dictionary<String,AnyObject!>> = Array<Dictionary<String,AnyObject!>>()
        var t:Array<Dictionary<String,AnyObject!>> = self.cache
        let len = t.count
        for var i = 0 ; i < len ; i++ {
            c.append(t[i])
        }
        // 更新対象のデータを取得+マージ.
        for (k,v) in values {
            let key = k.description
            let val = v as? NSDictionary
            var cc:Dictionary<String,AnyObject!> = Dictionary<String,AnyObject!>()
            for (kk,vv) in val! {
                cc[kk as! String] = vv
            }
            cc["room"] = key
            let p = searchRoom(key)
            if p == -1 {
                c.append(cc)
            }
            else {
                c[p] = cc
            }
        }
        // 更新データに対して、最終更新時間毎にソート.
        c.sortInPlace {$0["last_update_at"] as! Int > $1["last_update_at"] as! Int}
        
        // データ確保に対する最大値が定義されている場合.
        if max != nil {
            for ;c.count > max; {
                c.removeLast();
            }
        }
        // 新しいキャッシュセット.
        self.cache = c
    }
    
}

// ユーザアプリトーク管理.
class FirebaseByRedishUserApps {
    
    // ユーザID.
    private var userId:Int = -1
    
    // ルームスタッフID.
    private var merchantUserId = -1
    
    // ユーザ情報.
    private var user:RedishFirebaseElement! = nil
    
    // 既読監視用情報.
    private var already:RedishFirebaseElement! = nil
    
    // メッセージ群.
    private var messages:RedishFirebaseElement! = nil
    
    // 生成フラグ.
    private var createFlag:Bool = false
    
    // 初期処理.
    func create(id:Int, limit:UInt, call: (FIRDataSnapshot!) -> Void) {
        _ = AutoSync( self )
        destroy()
        
        // 基本監視領域を作成.
        self.userId = id
        self.user = CORE.createElement("/users/u\(id)/")
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
        
        var value:Dictionary<String,AnyObject!> = Dictionary<String,AnyObject!>()
        value[uKey] = "true"
        value[muKey] = "true"
        CORE.setValue(ref, key: key, value: value)
    }
    
    // 対象スタッフIDに対して、メッセージ送信.
    func send(merchantUserId:Int, type:Int, message:String) {
        _ = AutoSync( self )
        
        let uKey = "u\(self.userId)"
        let muKey = "mu\(merchantUserId)"
        let now:Int = Int(NSDate().timeIntervalSince1970) ;
        
        // messagesにセット.
        let messageRef = CORE.createReference("/messages/\(uKey)_\(muKey)/")
        CORE.addValue(messageRef, value: ["message": message, "type": "\(type)", "sender": uKey, "send_at": now])
        
        // usersにセット.
        // ユーザ用.
        let userRef = CORE.createReference("/users/\(uKey)/\(uKey)_\(muKey)/")
        CORE.updateValueAndAddCount(userRef, target:"unread_number", values:["last_update_at": now, "last_message": message])
        
        // 店舗スタッフ用.
        let merchantUserRef = CORE.createReference("/users/\(muKey)/\(uKey)_\(muKey)/")
        CORE.updateValueAndAddCount(merchantUserRef, target:"unread_number", values:["last_update_at": now, "last_message": message])
    }
    
    // 自分のメッセージを既読にする.
    private func alreadyRead(merchantUserId:Int) {
        // 未読カウントをクリア.
        let now:Int = Int(NSDate().timeIntervalSince1970) ;
        let ref = CORE.createReference("/users/u\(self.userId)/u\(self.userId)_mu\(merchantUserId)/")
        CORE.updateValue(ref, values:["last_read_at": now, "last_update_at": now, "unread_number": 0])
    }
    
    // 対象スタッフIDのルーム監視開始.
    func startMonitor(merchantUserId:Int, limit:UInt, call: (FIRDataSnapshot!) -> Void,
                      opponentCall: (FIRDataSnapshot!) -> Void) {
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
        var ay:RedishFirebaseElement! = self.already
        if ay == nil {
            ay = CORE.createElement("/users/\(muKey)/\(key)")
            self.already = ay
        }
        
        // 監視開始.
        e.hnd = CORE.startMonitorToAdded(e.ref, limit: limit, call: { snapshot in
            self.alreadyRead(merchantUserId)
            call(snapshot)
        })
        // 既読監視用更新.
        ay.hnd = CORE.startMonitor(ay.ref, limit: limit, call:opponentCall)
        self.merchantUserId = merchantUserId
        alreadyRead(merchantUserId)
    }
    
    // 対象スタッフIDのルーム監視終了.
    func stopMonitor() {
        _ = AutoSync( self )
        
        var e:RedishFirebaseElement! = self.messages
        self.messages = nil
        CORE.destroyElement(e)
        e = self.already
        self.already = nil
        CORE.destroyElement(e)
        self.merchantUserId = -1
    }
}

// FireAuth初期化処理.
// かならず1度だけ呼び出す必要がある.
private var initFirebaseFlag:Bool = false
func initFirebase() {
    _ = AutoSync( initFirebaseFlag ) ;
    if !initFirebaseFlag {
        FIRApp.configure()
        initFirebaseFlag = true
    }
}
