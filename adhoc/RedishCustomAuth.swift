//
//  RedishCustomAuth.swift
//  adhoc
//
//  Created by 鈴木政人 on 2016/07/28.
//  Copyright © 2016年 adhoc. All rights reserved.
//
import Foundation
import Firebase
import FirebaseAuth
import FirebaseAnalytics
import SwiftyJSON

// Firebaseカスタム認証処理用.
class RedishCustomAuth {
    private let DEFAULT_USER_AGENT = "redish-user-app"
    private var initFireAuthFlag:Bool = false
    private var authFlag:Bool = false
    
    // FireAuth初期化処理.
    // かならず1度だけ呼び出す必要がある.
    func initFireAuth() {
        _ = AutoSync( self ) ;
        if !initFireAuthFlag {
            FIRApp.configure()
            initFireAuthFlag = true
        }
    }
    
    // indexOf.
    private func indexOf( a:String,n:String ) -> Int {
        let s:NSString = a ;
        let range = s.rangeOfString( n )
        return (range.length > 0) ? range.location : -1
    }
    
    // URLパラメータをエンコード.
    private func httpEncode(params:Array<AnyObject>) -> String {
        let len = params.count ;
        if( len == 0 ) {
            return "" ;
        }
        var ret = "" ;
        for( var i = 0 ;i < len ; i += 2 ) {
            if( i != 0 ) {
                ret += "&\(params[ i ])=\(params[ i+1 ])" ;
            }
            else {
                ret = "\(params[ i ])=\(params[ i+1 ])" ;
            }
        }
        return ret.stringByAddingPercentEncodingWithAllowedCharacters(
            NSCharacterSet.URLQueryAllowedCharacterSet())! ;
    }
    
    // HTTPヘッダをセット.
    private func setHeaders(request:NSMutableURLRequest, headers:Array<AnyObject>!) {
        if headers != nil {
            let len = headers.count ;
            for( var i = 0 ;i < len ; i += 2 ) {
                request.setValue("\(headers[i+1])", forHTTPHeaderField: "\(headers[i])")
            }
        }
    }
    
    // [GET]HttpClient.
    private func httpGet(url:String,params:Array<AnyObject>!,headers:Array<AnyObject>!,callback:(Bool,String) -> Void) {
        var urlGet = url ;
        if( params != nil && params.count > 0 ) {
            if( indexOf( urlGet,n: "?" ) == -1 ) {
                urlGet = "\(urlGet)?\(httpEncode( params ))" ;
            }
            else {
                urlGet = "\(urlGet)&\(httpEncode( params ))" ;
            }
        }
        let request = NSMutableURLRequest(URL: NSURL(string: urlGet)!)
        request.HTTPMethod = "GET"
        request.setValue(DEFAULT_USER_AGENT, forHTTPHeaderField: "User-Agent")
        setHeaders(request, headers: headers)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()) ;
        let task = session.dataTaskWithRequest(request,
                                               completionHandler: {data, response, error in
                                                // セッションの解放(メモリーリーク対応).
                                                session.invalidateAndCancel() ;
                                                if( error == nil ) {
                                                    callback( true, NSString( data:data!,encoding:NSUTF8StringEncoding ) as! String ) ;
                                                }
                                                else {
                                                    callback( false, "{error:[\(error)]}" ) ;
                                                }
        })
        task.resume() ;
    }
    
    // カスタムタグ取得タグ.
    private let BASE_PATH = "/v1/user/custom_token/"
    
    // redishUserTokenHeader名.
    private let REDISH_USER_TOKEN = "Redish-Access-Token"
    
    // ログイン.
    func login(domain:String, redishUserToken:String, callback:(Bool,String) -> Void) -> Bool {
        _ = AutoSync( self )
        httpGet("\(domain)\(BASE_PATH)", params: nil, headers: [REDISH_USER_TOKEN,redishUserToken], callback: {resType, response in
            let json = JSON(data: response.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
            if let token = json["token"].string {
                FIRAuth.auth()?.signInWithCustomToken(token) { (user, error) in
                    debugPrint( "######### \(user)\n\(error)")
                    if error != nil {
                        callback(false, "Firebaseカスタム認証に失敗しました")
                        return
                    }
                    self.authFlag = true
                    callback(true, "")
                    
                }
            }
            else {
                if let error = json["error"].array {
                    callback(false,"\(error[0])")
                }
                else {
                    callback(false,"\(response)")
                }
            }
        })
        return true
    }
    
    // ログアウト.
    func logout() {
        _ = AutoSync( self )
        try! FIRAuth.auth()!.signOut()
        self.authFlag = false
    }
    
    // ログイン済みかチェック.
    // ただし、Expireで強制切断された場合は、この処理で見分けれない.
    func isLogin() -> Bool {
        _ = AutoSync( self )
        return self.authFlag
    }
}

