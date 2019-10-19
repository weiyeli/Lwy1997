//
//  ChildViewController1.swift
//  ChildViewController-demo
//
//  Created by liweiye on 2019/5/28.
//  Copyright © 2019 liweiye. All rights reserved.
//

import UIKit

class ChildViewController1: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red

        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        button.setTitle("退出", for: .normal)
        button.addTarget(self, action: #selector(quit), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc func quit() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        self.removeFromParent()
    }
}
