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
        
        var val = redishFirebaseRoomCache.get("u1_mu1")
        if val != nil {
            self.room1_label.text = val!["last_message"]?.description
        }
        val = redishFirebaseRoomCache.get("u1_mu2")
        if val != nil {
            self.room2_lavel.text = val!["last_message"]?.description
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
