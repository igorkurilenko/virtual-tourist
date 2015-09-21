//
//  BaseUIViewController.swift
//  Virtual Tourist
//
//  Created by kurilenko igor on 9/21/15.
//  Copyright © 2015 igor kurilenko. All rights reserved.
//

import Foundation
import UIKit

let ViertualTouristMessageNotificationKey = "com.virtual-tourist.notification"

class BaseUIViewController: UIViewController {
    
    internal let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        notificationCenter.addObserver(self, selector: "onMessageNotification:",
            name: ViertualTouristMessageNotificationKey, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        notificationCenter.removeObserver(self)
    }
    
    func onMessageNotification(notification: NSNotification) {
        if let payload = notification.userInfo as? Dictionary<String, MessageNotification> {
            if let messageNotification = payload["messageNotification"] {
                if messageNotification.messageStyle == MessageStyle.Error {
                    alert(messageNotification.message)
                }
            }
        }
    }
    
    func alert(message: Message) {
        let alert = UIAlertController(
            title: message.title,
            message: message.description,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension BaseUIViewController {
    internal func alertError(error: NSError) {
        dispatch_async(dispatch_get_main_queue(), {
            let message = Message.create(error)
            
            self.displayErrorMessage(message)
        })
    }
    
    private func displayMessage(message: Message) {
        let messageNotification = MessageNotification(message: message)
        
        postNotification(messageNotification)
    }
    
    func displayErrorMessage(message: Message) {
        let messageNotification = MessageNotification(message: message, messageStyle: .Error)
        
        postNotification(messageNotification)
    }
    
    private func postNotification(messageNotification: MessageNotification) {
        notificationCenter.postNotificationName(ViertualTouristMessageNotificationKey, object: nil,
            userInfo: ["messageNotification": messageNotification])
    }
}