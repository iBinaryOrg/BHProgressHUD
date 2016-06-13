//
//  ViewController.swift
//  BHProgressHUD-Demo
//
//  Created by Raykle on 16/6/1.
//  Copyright © 2016年 iBinaryOrg. All rights reserved.
//

import UIKit

struct BHExample {
    let title: String?
    let selector: Selector?
}


class ViewController: UITableViewController, BHProgressHUDDelegate {
    
    var canceled: Bool?
    
    let examples = [
        [
            BHExample(title: "Indeterminate mode", selector: #selector(indeterminateExample)),
            BHExample(title: "With label", selector: #selector(labelExample)),
            BHExample(title: "With details label", selector: #selector(detailsLabelExample))
        ],
        [
            BHExample(title: "Determinate mode", selector: #selector(determinateExample)),
            BHExample(title: "Annular determinate mode", selector: #selector(annularDeterminateExample)),
            BHExample(title: "Bar determinate mode", selector: #selector(barDeterminateExample))
        ],
        [
            BHExample(title: "Text only", selector: #selector(textExample)),
            BHExample(title: "Custom view", selector: #selector(customViewExample)),
            BHExample(title: "With action button", selector: #selector(cancelationExample)),
            BHExample(title: "Mode switching", selector: #selector(modeSwitchingExample))
        ],
        [
            BHExample(title: "On window", selector: #selector(indeterminateExample)),
            BHExample(title: "NSURLSession", selector: #selector(networkingExample)),
            BHExample(title: "Dim background", selector: #selector(indeterminateExample)),
            BHExample(title: "Colored", selector: #selector(indeterminateExample))
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Private
    func doSomeWork() {
        sleep(3)
    }
    
    func doSomeWorkWithProgress() {
        self.canceled = false
        var progress: Float = 0.0
        while progress < 1.0 {
            if self.canceled == true {
                break
            }
            
            progress += 0.01
            dispatch_async(dispatch_get_main_queue(), { 
                BHProgressHUD.HUDForView(self.navigationController!.view)?.progress = progress
            })
        }
        usleep(50000)
    }
    
    func cancelWork(button: UIButton) {
        self.canceled = true
    }
    
    func doSomeWorkWithMixedProgress() {
        let hud = BHProgressHUD.HUDForView(self.navigationController!.view)
        sleep(2)
        dispatch_async(dispatch_get_main_queue()) { 
            hud?.mode = .Determinate
            hud?.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        }
        
        var progress: Float = 0.0
        while progress < 1.0 {
            progress += 0.01
            dispatch_async(dispatch_get_main_queue(), { 
                hud?.progress = progress
            })
            usleep(50000)
        }
        
        dispatch_async(dispatch_get_main_queue()) { 
            hud?.mode = .Indeterminate
            hud?.label?.text = NSLocalizedString("Cleaning up...", comment: "HUD cleanining up title")
        }
        sleep(2)
        
        dispatch_sync(dispatch_get_main_queue()) { 
            let image = UIImage(named: "Checkmark")?.imageWithRenderingMode(.AlwaysTemplate)
            let imageView = UIImageView(image: image)
            hud?.customView = imageView
            hud?.mode = .CustomView
            hud?.label?.text = NSLocalizedString("Completed", comment: "HUD completed title")
        }
        
        sleep(2)
    }
    
    func doSomeNetworkWorkWithProgress() {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let URL = NSURL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip")
        let task = session.downloadTaskWithURL(URL!)
        task.resume()
    }
    
    //MARK: - Selectors
    func indeterminateExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: false)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWork()
            
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func labelExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWork()
            
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func detailsLabelExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        hud.detailsLabel?.text = NSLocalizedString("Parsing data\n(1/1)", comment: "HUD title")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWork()
            
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func windowExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.view.window!, animated: true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWork()
            
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func determinateExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .Determinate
        hud.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWorkWithProgress()
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func annularDeterminateExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .DeterminateHorizontalBar
        hud.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWorkWithProgress()
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func barDeterminateExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .DeterminateHorizontalBar
        hud.label?.text = NSLocalizedString("Loading...", comment: "HUD loading title")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWorkWithProgress()
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func customViewExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .CustomView
        
        let image = UIImage(named: "Checkmark")?.imageWithRenderingMode(.AlwaysTemplate)
        hud.customView = UIImageView(image: image)
        hud.square = true
        hud.label?.text = NSLocalizedString("Done", comment: "HUD done title")
        
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    func textExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .Text
        hud.label?.text = NSLocalizedString("Message here!", comment: "HUD message title")
        hud.offset = CGPointMake(0.0, BHProgressMaxOffset)
        
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    func cancelationExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.mode = .Determinate
        hud.label?.text = NSLocalizedString("Loading", comment: "HUD loading title")

        hud.button?.setTitle(NSLocalizedString("Cancel", comment: "HUD cancel button title"), forState: .Normal)
        hud.button?.addTarget(self, action: #selector(cancelWork(_:)), forControlEvents: .TouchUpInside)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
            self.doSomeWorkWithProgress()
            
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func modeSwitchingExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.label?.text = NSLocalizedString("Preparing...", comment: "HUD prepare title")
        hud.minSize = CGSizeMake(150.0, 100.0)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { 
           self.doSomeWorkWithMixedProgress()
            dispatch_async(dispatch_get_main_queue(), { 
                hud.hide(animated: true)
            })
        }
    }
    
    func networkingExample() {
        let hud = BHProgressHUD.showHUD(addedTo: self.navigationController!.view, animated: true)
        hud.label?.text = NSLocalizedString("Preparing...", comment: "HUD prepareing title")
        hud.minSize = CGSizeMake(150.0, 100.0)
        
        self.doSomeWorkWithProgress()
    }
    
    //MARK: BHProgressHUD Delegate
    func hudWasHidden(hud: BHProgressHUD) {
        print(String(format: "-------- %@ --------", #function))
    }
}

// MARK: - TableView Delegate & DataSource
extension ViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.examples.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.examples[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let example = self.examples[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("BHExampleCell", forIndexPath: indexPath)
        cell.textLabel?.text = example.title
        cell.textLabel?.textColor = self.view.tintColor
        cell.textLabel?.textAlignment = .Center
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = cell.textLabel?.textColor.colorWithAlphaComponent(0.1)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let example = self.examples[indexPath.section][indexPath.row]
        self.performSelector(example.selector!)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(0.1) * NSEC_PER_SEC)), dispatch_get_main_queue(), {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        })
    }
}

extension ViewController: NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        dispatch_async(dispatch_get_main_queue()) { 
            let hud = BHProgressHUD.HUDForView(self.navigationController!.view)!
            let image = UIImage(named: "Checkmark")?.imageWithRenderingMode(.AlwaysTemplate)
            let imageView = UIImageView(image: image)
            hud.customView = imageView
            hud.mode = .CustomView
            hud.label?.text = NSLocalizedString("Completed", comment: "HUD completed title")
            hud.hide(animated: true, afterDelay: 3.0)
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        dispatch_async(dispatch_get_main_queue()) { 
            let hud = BHProgressHUD.HUDForView(self.navigationController!.view)!
            hud.mode = .Determinate
            hud.progress = progress
        }
    }
}

