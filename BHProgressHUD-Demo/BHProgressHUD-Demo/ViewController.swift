//
//  ViewController.swift
//  BHProgressHUD-Demo
//
//  Created by Raykle on 16/6/1.
//  Copyright © 2016年 iBinaryOrg. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showAction() {
        BHProgressHUD.showHUD(addedTo: self.view, animated: true)
    }
    
    @IBAction func hideAction() {
        BHProgressHUD.hideHUD(forView: self.view, animated: true)
    }
}

