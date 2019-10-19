//
//  ViewController.swift
//  Notification-demo
//
//  Created by liweiye on 2019/6/1.
//  Copyright © 2019 liweiye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let notificationCenter = NotificationCenter.default
        let operationQueue = OperationQueue.main

        let observer = notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                      object: nil,
                                                      queue: operationQueue) { (notification) in
                                                        print("程序进入后台了")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

