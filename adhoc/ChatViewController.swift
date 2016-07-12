//
//  ChatViewController.swift
//  adhoc
//
//  Created by 鈴木政人 on 2016/07/12.
//  Copyright © 2016年 adhoc. All rights reserved.
//

import Foundation

import UIKit

class ChatViewController : UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var messageText: UITextField!
    @IBOutlet weak var userLavel: UILabel!
    @IBOutlet weak var topButton: UIButton!
    
    
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ラベルセット.
        userLavel.text = "u\(userId)_mu\(merchantUserId)"
        
        // ルーム情報を監視.
        redishFirebase.startMonitor(merchantUserId,limit:FIREBASE_LIMIT,call: { snapshot in
            if let name = snapshot.value!.objectForKey("sender") as? String,
                message = snapshot.value!.objectForKey("message") as? String {
                    self.textView.text = "\(self.textView.text)\n\(name) : \(message)"
            }
        })
        
        
    }
    
    @IBAction func topButtonDown(sender: AnyObject) {
        redishFirebase.stopMonitor()
    }
    
    // 送信.
    @IBAction func sendButtonDown(sender: AnyObject) {
        let text:String = messageText.text!
        messageText.text = ""
        if text.characters.count > 0 {
            redishFirebase.send(merchantUserId, message: text)
        }
    }
}