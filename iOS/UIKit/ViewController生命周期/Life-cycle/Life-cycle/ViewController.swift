//
//  ViewController.swift
//  Life-cycle
//
//  Created by liweiye on 2019/5/22.
//  Copyright © 2019 liweiye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController1：viewDidLoad has been called")
        button.addTarget(self, action: #selector(didCliked), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController1：viewWillAppear has been called")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("ViewController1：viewWillLayoutSubviews has been called")
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("ViewController1：viewDidLayoutSubviews has been called")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ViewController1：viewDidAppear has been called")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ViewController1：viewWillDisappear has beeen called")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("ViewController1：viewDidDisappear has been called")
    }

    @objc func didCliked() {
        self.navigationController?.pushViewController(ViewController2(), animated: true)
    }
}

