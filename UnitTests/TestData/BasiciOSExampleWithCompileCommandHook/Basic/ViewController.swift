//
//  ViewController.swift
//  Basic
//
//  Created by Jerry Marino on 5/13/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let monster = Monster()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        // Here we are calling a custom method on the AppDelegate
//        delegate.cu
    }
}

