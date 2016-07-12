//
//  TopPageViewController.swift
//  adhoc
//
//  Created by 鈴木政人 on 2016/07/12.
//  Copyright © 2016年 adhoc. All rights reserved.
//

import Foundation

import UIKit

class TopPageViewController : UIViewController {
    @IBOutlet weak var room1_u1_mu1: UIButton!
    @IBOutlet weak var room2_u1_mu2: UIButton!
    @IBOutlet weak var room1_label: UILabel!
    @IBOutlet weak var room2_lavel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        room1_label.text = "メッセージなし"
        room2_lavel.text = "メッセージなし"
        
        // 生成されていない場合処理.
        if !redishFirebase.isCreate() {
            
            // 生成＋ユーザ情報の監視.
            redishFirebase.create( userId,limit:1,call: { snapshot in
                if let value:AnyObject! = snapshot.value!,
                    room = value.objectForKey("room") as? String,
                    lastMessage = value.objectForKey("last_message") as? String {
                    if room == "u1_mu1" {
                        self.room1_label.text = lastMessage
                    } else if room == "u1_mu2" {
                        self.room2_lavel.text = lastMessage
                    }
                }
            })
        }
    }
    
    @IBAction func room1_u1_mu1_down(sender: AnyObject) {
        merchantUserId = 1
        
        // ルーム移動.
        moveRoom()
    }
    
    
    @IBAction func room2_u1_mu2_down(sender: AnyObject) {
        merchantUserId = 2
        
        // ルーム移動.
        moveRoom()
    }
    
    // ルーム移動.
    private func moveRoom() {
        
        // ルーム作成.
        // 本来はここでなく、新しくチャットを開始する時に実施する。
        redishFirebase.createRoom(merchantUserId)
    }
    
}
