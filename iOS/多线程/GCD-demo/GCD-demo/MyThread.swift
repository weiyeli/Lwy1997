//
//  MyThread.swift
//  GCD-demo
//
//  Created by liweiye on 2019/5/30.
//  Copyright © 2019 liweiye. All rights reserved.
//

import Foundation

class MyThread: Thread {
    override func main() {
        print("Thread started, sleep for 2 seconds...")
        Thread.sleep(forTimeInterval: 2)
        print("Done sleeping, exiting thread")
    }
}
