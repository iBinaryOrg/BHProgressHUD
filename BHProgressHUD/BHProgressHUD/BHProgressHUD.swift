//
//  BHProgressHUD.swift
//  BHProgressHUD
//
//  Created by Raykle on 16/6/1.
//  Copyright © 2016年 iBinaryOrg. All rights reserved.
//

import UIKit

enum BHProgressHUDMode: Int {
    case Indeterminate = 0
    case Determinate
    case DeterminateHorizontalBar
    case AnnularDeterminate
    case CustomView
    case Text
}

enum BHProgressHUDAnimation: Int {
    case Fade = 0
    case Zoom
    case ZoomOut
    case ZoomIn
}

enum BHProgressHUDBackgroundStyle: Int {
    case SolidColor = 0
    case Blur
}

@objc protocol BHProgressHUDDelegate {
    optional func hudWasHidden(hud: BHProgressHUD);
}

class BHProgressHUD: UIView {
    
    weak var delegate: BHProgressHUDDelegate?
    var removeFromSuperViewOnHide: Bool = false
    var mode: BHProgressHUDMode = .Indeterminate
    //var contentColor: UIColor
    var animationType: BHProgressHUDAnimation = .Fade
    var yOffset = 0.0
    var margin = 20.0
    var minSize: CGSize = CGSizeZero
    var square: Bool = false
    var progress = 0.0
    var customView: UIView?
    var label: UILabel!
    var detailsLabel: UILabel!
    var button: UIButton!
    
    //MARK: Life Cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .Center
        self.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        self.backgroundColor = UIColor.clearColor()
        self.alpha = 0.0
    }
    
    convenience init(view: UIView?) {
        assert(view != nil, "View Must Not Be nil!")
        self.init(frame: view!.bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("HUD deinited.")
    }
    
    //MARK: Show & Hide
    func show(animated animated: Bool) {
        
    }
    
    func hide(animated animated: Bool) {
        
    }
    
    func hide(animated animated: Bool, afterDelay: NSTimeInterval) {
        
    }
}

//MARK: - Class Methods
extension BHProgressHUD {
    class func showHUD(addedTo view: UIView, animated: Bool) -> BHProgressHUD {
        
        let hud = BHProgressHUD(view: view)
        
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        
        return hud
    }
    
    class func hideHUD(forView view: UIView, animated: Bool) -> Bool {
        return true
    }
    
    class func HUDForView(view: UIView) -> BHProgressHUD? {
        return nil
    }
}

//MARK: - BHRoundProgressView
class BHRoundProgressView: UIView {
    var progress: Float = 0.0
    var progressTintColor: UIColor
    var backgroundTintColor: UIColor
    var annular: Bool = false
    
    //MARK: Life Cycle
    override init(frame: CGRect) {
        progressTintColor = UIColor(white: 1.0, alpha: 1.0)
        backgroundTintColor = UIColor(white: 1.0, alpha: 1.0)
        
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.opaque = false
    }
    
    convenience init() {
        self.init(frame: CGRectMake(0.0, 0.0, 37.0, 37.0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Draw
    override func drawRect(rect: CGRect) {
        
    }
}

//MARK: - BHBarProgressView
class BHBarProgressView: UIView {
    var progress: Float
    var lineColor: UIColor
    var progressRemainingColor: UIColor
    var progressColor: UIColor
    
    //MARK: Life Cycle
    override init(frame: CGRect) {
        progress = 0.0
        lineColor = UIColor.whiteColor()
        progressRemainingColor = UIColor.clearColor()
        progressColor = UIColor.whiteColor()
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        self.opaque = false
    }
    
    convenience init() {
        self.init(frame: CGRectMake(0.0, 0.0, 120.0, 20.0))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Draw
    override func drawRect(rect: CGRect) {
        
    }
}

