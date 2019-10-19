//
//  ViewController.swift
//  ChildViewController-demo
//
//  Created by liweiye on 2019/5/28.
//  Copyright © 2019 liweiye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var enterButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        enterButton.addTarget(self, action: #selector(enterChildVC1), for: .touchUpInside)
    }

    @objc private func enterChildVC1() {
        // 创建一个子控制器
        let childVC1 = ChildViewController1()
        self.addChild(childVC1)
        self.view.addSubview(childVC1.view)
        childVC1.didMove(toParent: self)
    }
}

