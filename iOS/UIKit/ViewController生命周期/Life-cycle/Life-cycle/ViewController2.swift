//
//  ViewController2.swift
//  Life-cycle
//
//  Created by liweiye on 2019/5/22.
//  Copyright © 2019 liweiye. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController2：viewDidLoad has been called")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ViewController2：viewWillAppear has been called")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("ViewController2：viewWillLayoutSubviews has been called")
    }

    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("ViewController2：viewDidLayoutSubviews has been called")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ViewController2：viewDidAppear has been called")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("ViewController2：viewWillDisappear has beeen called")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("ViewController2：viewDidDisappear has been called")
    }
}
