//
//  AppDelegate.swift
//  adhoc
//
//  Created by 鈴木政人 on 2016/07/11.
//  Copyright © 2016年 adhoc. All rights reserved.
//

import UIKit

// 定義.
let FIREBASE_LIMIT:UInt = 10
let MAX_ROOM_LIMIT:UInt = 30
let DOMAIN:String = "http://127.0.0.1:3000"

// この値はサーバの初期化で変更されるので、注意.
let USER_TOKEN = "cd1548e602215db12994eda3eca958bc5288928d3c5b2edb6aaac527946a246c"

// グローバル定義.
let redishFirebase:FirebaseByRedishUserApps = FirebaseByRedishUserApps()
let redishFirebaseRoomCache:FirebaseRoomCache = FirebaseRoomCache()
let redishCustomToken:RedishCustomAuth = RedishCustomAuth()

var userId:Int = 1
var merchantUserId:Int = -1

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        /*
        redishCustomToken.initFireAuth()
        
        // カスタムトークン実施.
        redishCustomToken.login(DOMAIN, redishUserToken: USER_TOKEN, callback: { resultFlag,result in
            // カスタムトークン認証が成功した場合.
            if resultFlag == true {
                
                // 生成＋ユーザ情報の監視.
                redishFirebase.create( userId,limit:MAX_ROOM_LIMIT,call: { snapshot in
                    if let values = snapshot.value as? NSDictionary {
                        redishFirebaseRoomCache.update(Int(MAX_ROOM_LIMIT), values: values)
                    }
                })
            }
            else {
                debugPrint( "アクセストークンのアクセスに失敗:\(result)")
            }
        })
 */
        
        // 生成＋ユーザ情報の監視.
        redishFirebase.create( userId,limit:MAX_ROOM_LIMIT,call: { snapshot in
            if let values = snapshot.value as? NSDictionary {
                redishFirebaseRoomCache.update(Int(MAX_ROOM_LIMIT), values: values)
            }
        })
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

