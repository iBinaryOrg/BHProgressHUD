//
//  BHProgressHUD.swift
//  BHProgressHUD
//
//  Created by Raykle on 16/6/1.
//  Copyright © 2016年 iBinaryOrg. All rights reserved.
//

import UIKit
import Dispatch

// MARK: Enum
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

// MARK: - Protocol
@objc protocol BHProgressHUDDelegate {
    optional func hudWasHidden(hud: BHProgressHUD);
}
// MARK: - Global var
let kDefaultPadding: CGFloat = 4.0
let kDefaultLabelFontSize: CGFloat = 16.0
let kDefaultDetailLabelFontSize: CGFloat = 12.0

private func BHMainThreadAssert() {
    assert(NSThread.isMainThread(), "MBProgressHUD needs to be accessed on the main thread.")
}

// MARK: - Class
class BHProgressHUD: UIView {
    
    //MARK: Public var
    weak var delegate: BHProgressHUDDelegate?
    
    var graceTime: NSTimeInterval?
    var minShowTime: NSTimeInterval?
    var removeFromSuperViewOnHide: Bool = false
    var animationType: BHProgressHUDAnimation = .Fade
    var offset = CGPoint(x: 0, y: 0)
    var margin: CGFloat = 20.0
    var defaultMotionEffectsEnabled: Bool = true
    var contentColor: UIColor?
    
    var minSize: CGSize = CGSizeZero
    var square: Bool = false
    var progress = 0.0
    var backgroundView: BHBackgroundView?
    var bezelView: BHBackgroundView?
    var customView: UIView?
    var label: UILabel?
    var detailsLabel: UILabel?
    var button: UIButton?
    
    //MARK: Observe
    var mode: BHProgressHUDMode = .Indeterminate {
        didSet {
            if mode != oldValue {
                self.updateIndicators()
            }
        }
    }
    
    //MARK: Private var
    private var opacity: Float = 1.0
    private var activityIndicatorColor: UIColor?
    private var useAnimation: Bool = true
    private var finished: Bool = false
    private var indicator: UIView?
    private var showStarted: NSDate?
    private var paddingConstraints: [NSLayoutConstraint]?
    private var bezelConstraints: [NSLayoutConstraint]?
    private var topSpacer: UIView?
    private var bottomSpacer: UIView?
    
    private var graceTimer: NSTimer?
    private var minShowTimer: NSTimer?
    private var hideDelayTimer: NSTimer?
    
    //MARK: Life Cycle
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        self.commonInit()
    }
    
    convenience init(view: UIView?) {
        assert(view != nil, "View must not be nil.")
        self.init(frame: view!.bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("HUD deinited.")
    }
    
    private func commonInit() {
        let isLegacy = kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0
        contentColor = isLegacy ? UIColor.whiteColor() : UIColor(white: 0.0, alpha: 0.7)
        
        self.opaque = false
        self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.backgroundColor = UIColor.clearColor()
        self.alpha = 0.0
        self.layer.allowsGroupOpacity = false
        
        self.setupViews()
        self.updateIndicators()
    }
    
    //MARK: Show & Hide
    func show(animated animated: Bool) {
        BHMainThreadAssert()
        minShowTimer?.invalidate()
        useAnimation = animated
        finished = false
        // If the grace time is set, postpone the HUD display
        if graceTime > 0.0 {
            let timer = NSTimer.init(timeInterval: graceTime!, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
            graceTimer = timer
        }
        // ... otherwise show the HUD imediately 
        else {
            self.show(usingAnimation: useAnimation)
        }
    }
    
    func hide(animated animated: Bool) {
        BHMainThreadAssert()
        graceTimer?.invalidate()
        finished = true
        // If the minShow time is set, calculate how long the HUD was shown,
        // and postpone the hiding operation if necessary
        if minShowTime > 0.0 && showStarted != nil {
            let interv: NSTimeInterval = NSDate().timeIntervalSinceDate(showStarted!)
            if interv < minShowTime {
                let timer = NSTimer.init(timeInterval: minShowTime! - interv, target: self, selector: #selector(handleMinShowTimer(_:)), userInfo: nil, repeats: false)
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                minShowTimer = timer
                return
            }
        }
        // ... otherwise hide the HUD immediately
        self.hide(usingAnimation: useAnimation)
    }
    
    func hide(animated animated: Bool, afterDelay: NSTimeInterval) {
        
    }
    
    //MARK: Timer callbacks
    @objc private func handleGraceTimer(theTimer: NSTimer) {
        if !finished {
            self.show(usingAnimation: useAnimation)
        }
    }
    
    @objc private func handleMinShowTimer(theTimer: NSTimer) {
        self.hide(usingAnimation: useAnimation)
    }
    
    @objc private func handleHideTimer(theTimer: NSTimer) {
        self.hide(animated: (theTimer.userInfo?.boolValue)!)
    }
    
    //MARK: View Hierrarchy
    override func didMoveToSuperview() {
        self.updateForCurrentOrientation(animated: false)
    }
    
    //MARK: Internal show & hide operations
    private func show(usingAnimation animated: Bool) {
        bezelView?.layer.removeAllAnimations()
        backgroundView?.layer.removeAllAnimations()
        
        hideDelayTimer?.invalidate()
        
        showStarted = NSDate()
        self.alpha = 1.0
        
        if animated {
            self.animateIn(true, type: self.animationType, completion: nil)
        } else {
            self.bezelView?.alpha = CGFloat(opacity)
            self.backgroundView?.alpha = 1.0
        }
    }
    
    private func hide(usingAnimation animated: Bool) {
        if animated && showStarted != nil {
            showStarted = nil
            self.animateIn(false, type: animationType, completion: { (finished) in
                self.done(finished: finished)
            })
        } else {
            showStarted = nil
            bezelView?.alpha = 0.0
            backgroundView?.alpha = 0.0
            self.done(finished: true)
        }
    }
    
    private func animateIn(animategIn: Bool, type: BHProgressHUDAnimation, completion: ((Bool) -> ())?) {
        // Automatically determine the correct zoom animation type
        var newType: BHProgressHUDAnimation = type
        if type == .Zoom {
            newType = animategIn ? .ZoomIn : .ZoomOut
        }
        
        let small = CGAffineTransformMakeScale(0.5, 0.5)
        let large = CGAffineTransformMakeScale(1.5, 1.5)
        
        // Set starting state
        if animategIn && bezelView?.alpha == 0 && newType == .ZoomIn {
            bezelView?.transform = small
        } else if animategIn && bezelView?.alpha == 0.0 && newType == .ZoomOut {
            bezelView?.transform = large
        }
        
        // Perform animations
        let animations:() -> () = {
            [weak self] in
            if let strongSelf = self {
                if animategIn {
                    strongSelf.bezelView?.transform = CGAffineTransformIdentity
                } else if !animategIn && newType == .ZoomIn {
                    strongSelf.transform = large
                } else if !animategIn && newType == .ZoomOut {
                    strongSelf.transform = small
                }
                
                strongSelf.bezelView?.alpha = animategIn ? 1.0 : 0.0
                strongSelf.backgroundView?.alpha = animategIn ? 1.0 : 0.0
            }
        }
        
        UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.BeginFromCurrentState], animations: animations, completion: completion)
    }
    
    private func done(finished finished: Bool) {
        // Cancel any scheduled hideDelayed: calls
        hideDelayTimer?.invalidate()
        
        if finished {
            self.alpha = 0.0
            if self.removeFromSuperViewOnHide {
                self.removeFromSuperview()
            }
        }
        
        delegate?.hudWasHidden?(self)
    }
    
    //MARK: UI
    private func setupViews() {
        let defaultColor = contentColor
        
        backgroundView = BHBackgroundView(frame: self.bounds)
        backgroundView!.style = .SolidColor
        backgroundView!.backgroundColor = UIColor.clearColor()
        backgroundView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        backgroundView!.alpha = 0.0
        self.addSubview(backgroundView!)
        
        bezelView = BHBackgroundView()
        bezelView!.translatesAutoresizingMaskIntoConstraints = false
        bezelView!.layer.cornerRadius = 5.0
        bezelView!.alpha = 0.0
        self.addSubview(bezelView!)
        self.updateBezelMotionEffects()
        
        label = UILabel()
        label!.adjustsFontSizeToFitWidth = false
        label!.textAlignment = .Center
        label!.textColor = defaultColor
        label!.font = UIFont.boldSystemFontOfSize(CGFloat(kDefaultLabelFontSize))
        label!.opaque = false
        label!.backgroundColor = UIColor.clearColor()
        
        detailsLabel = UILabel()
        detailsLabel!.adjustsFontSizeToFitWidth = false
        detailsLabel!.textAlignment = .Center
        detailsLabel!.textColor = defaultColor
        detailsLabel!.numberOfLines = 0
        detailsLabel!.font = UIFont.boldSystemFontOfSize(CGFloat(kDefaultDetailLabelFontSize))
        detailsLabel!.opaque = false
        detailsLabel!.backgroundColor = UIColor.clearColor()
        
        button = BHProgressHUDRoundedButton(type:.Custom)
        button!.titleLabel?.textAlignment = .Center
        button!.titleLabel?.font = UIFont.boldSystemFontOfSize(CGFloat(kDefaultDetailLabelFontSize))
        button!.setTitleColor(defaultColor, forState: .Normal)
        
        let viewAry: [UIView] = [label!, detailsLabel!, button!]
        for view: UIView in viewAry {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(998.0, forAxis: .Horizontal)
            view .setContentCompressionResistancePriority(998, forAxis: .Vertical)
            bezelView!.addSubview(view)
        }
        
        topSpacer = UIView()
        topSpacer!.translatesAutoresizingMaskIntoConstraints = false
        topSpacer!.hidden = true
        bezelView!.addSubview(topSpacer!)
        
        bottomSpacer = UIView()
        bottomSpacer!.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer!.hidden = true
        bezelView!.addSubview(bottomSpacer!)
    }
    
    private func updateIndicators() {
        let isActivityIndicator: Bool = indicator?.isKindOfClass(UIActivityIndicatorView.self) ?? false
        let isRoundIndicator: Bool = indicator?.isKindOfClass(BHRoundProgressView.self) ?? false
        
        if mode == .Indeterminate {
            if !isActivityIndicator {
                // Update to indeterminate indicator
                indicator?.removeFromSuperview()
                indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
                (indicator! as! UIActivityIndicatorView).startAnimating()
                bezelView?.addSubview(indicator!)
            }
        }
        else if mode == .DeterminateHorizontalBar {
            // Update to bar determinate indicator
            indicator?.removeFromSuperview()
            indicator = BHBarProgressView()
            bezelView?.addSubview(indicator!)
        }
        else if mode == .Determinate || mode == .AnnularDeterminate {
            if !isRoundIndicator {
                // Update to determinante indicator
                indicator?.removeFromSuperview()
                indicator = BHRoundProgressView()
                bezelView?.addSubview(indicator!)
            }
            if mode == .AnnularDeterminate {
                (indicator! as! BHRoundProgressView).annular = true
            }
        }
        else if mode == .CustomView && customView != indicator {
            // Update custom view indicator
            indicator?.removeFromSuperview()
            indicator = customView
            bezelView?.addSubview(indicator!)
        }
        else if mode == .Text {
            indicator?.removeFromSuperview()
            indicator = nil
        }
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        
//        if indicator?.respondsToSelector(#selector(setProgress(_:))) != nil {
//        indicator?.setValue(NSNumber(float: Float(self.progress)), forKey: "progress")
//        }
        
        indicator?.setContentCompressionResistancePriority(998.0, forAxis: .Horizontal)
        indicator?.setContentCompressionResistancePriority(998.0, forAxis: .Vertical)
        
        self.updateViewsForColor(contentColor)
        self.setNeedsUpdateConstraints()
    }
    
    private func updateViewsForColor(color: UIColor?) {
        if var color = color {
            label?.textColor = color
            detailsLabel?.textColor = color
            button?.setTitleColor(color, forState: .Normal)
            
            if let acIndicatorColor = self.activityIndicatorColor {
                color = acIndicatorColor
            }
            
            if ((indicator?.isKindOfClass(UIActivityIndicatorView.self)) == true) {
                (indicator! as! UIActivityIndicatorView).color = color
            }
        }
    }
    
    private func updateBezelMotionEffects() {
//        if #available(iOS 7.0, *) {}
        if bezelView?.respondsToSelector(#selector(addMotionEffect(_:))) == false {
            return
        }
        
        if defaultMotionEffectsEnabled == true {
            let effectOffset = 10.0
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = NSNumber(float: Float(effectOffset))
            effectX.minimumRelativeValue = NSNumber(float: Float(-effectOffset))
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
            effectY.maximumRelativeValue = NSNumber(float: Float(effectOffset))
            effectY.minimumRelativeValue = NSNumber(float: Float(-effectOffset))
            
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            
            bezelView?.addMotionEffect(group)
        } else {
            let effects = bezelView?.motionEffects
            for effect in effects! {
                bezelView?.removeMotionEffect(effect)
            }
        }
    }
    
    //MARK: Layout
    override func updateConstraints() {
        var bezelConstraints = [NSLayoutConstraint]()
        let metrics = ["margin": NSNumber(float: Float(margin))]
        
        let subviews: NSMutableArray = [topSpacer!, label!, detailsLabel!, button!, bottomSpacer!]
        if (indicator != nil) {
            subviews.insertObject(indicator!, atIndex: 1)
        }
        
        // Remove existing constraints
        self.removeConstraints(self.constraints)
        topSpacer?.removeConstraints(topSpacer!.constraints)
        bottomSpacer?.removeConstraints(bottomSpacer!.constraints)
        if (self.bezelConstraints != nil) {
            bezelView?.removeConstraints(self.bezelConstraints!)
            self.bezelConstraints = nil
        }
        
        // Center bezel in container (self), applying the offset if set
        var centeringConstraints = [NSLayoutConstraint]()
        centeringConstraints.append(NSLayoutConstraint(item: bezelView! , attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier:1.0, constant: offset.x))
        centeringConstraints.append(NSLayoutConstraint(item: bezelView! , attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier:1.0, constant: offset.y))
        self.applyPriority(998.0, toConstraints: centeringConstraints)
        self.addConstraints(centeringConstraints)
        
        // Ensure minimum side margin is kept
        var sideContraints = [NSLayoutConstraint]()
        sideContraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("|-(>=margin)-[bezel]-(>=margin)-|", options: [], metrics: metrics, views: ["bezel" : bezelView!]))
        sideContraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=margin)-[bezel]-(>=margin)-|", options: [], metrics: metrics, views: ["bezel" : bezelView!]))
        self.applyPriority(999.0, toConstraints: sideContraints)
        self.addConstraints(sideContraints)
        
        // Minimum bezel size, if set
        if !CGSizeEqualToSize(minSize, CGSizeZero) {
            var minSizeConstraints = [NSLayoutConstraint]()
            minSizeConstraints.append(NSLayoutConstraint(item: bezelView! , attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant: minSize.width))
            minSizeConstraints.append(NSLayoutConstraint(item: bezelView! , attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant: minSize.height))
            self.applyPriority(997.0, toConstraints: minSizeConstraints)
            bezelConstraints.appendContentsOf(minSizeConstraints)
        }
        
        // Square aspect ratio, if set
        if square {
            let squareConstraint = NSLayoutConstraint(item: bezelView! , attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: bezelView, attribute: NSLayoutAttribute.Width, multiplier:1.0, constant: 0)
            squareConstraint.priority = 997.0
            bezelConstraints.append(squareConstraint)
        }
        
        // Top and bottom spacing
        topSpacer!.addConstraint(NSLayoutConstraint(item: topSpacer! , attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant: margin))
        bottomSpacer!.addConstraint(NSLayoutConstraint(item: bottomSpacer! , attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant: margin))
        // Top and bottom spaces should be equal
        bezelConstraints.append(NSLayoutConstraint(item: topSpacer! , attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: bottomSpacer, attribute: NSLayoutAttribute.Height, multiplier:1.0, constant: 0.0))
        
        // Layout subviews in bezel
        var paddingConstraints = [NSLayoutConstraint]()
        subviews.enumerateObjectsUsingBlock { [weak self] (view, idx, stop) in
            // Center in bezel
            bezelConstraints.append(NSLayoutConstraint(item: view , attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self!.bezelView!, attribute: NSLayoutAttribute.CenterX, multiplier:1.0, constant: 0.0))
            // Ensure the minimum edge margin is kept
            bezelConstraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("|-(>=margin)-[view]-(>=margin)-|", options: [], metrics: metrics, views: ["view": view]))
            // Element spacing
            if idx == 0 {
                // First, ensure spacing to bezel edge
                bezelConstraints.append(NSLayoutConstraint(item: view , attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self!.bezelView!, attribute: NSLayoutAttribute.Top, multiplier:1.0, constant: 0.0))
            } else if idx == subviews.count - 1 {
                bezelConstraints.append(NSLayoutConstraint(item: view , attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self!.bezelView!, attribute: NSLayoutAttribute.Bottom, multiplier:1.0, constant: 0.0))
            }
            if idx > 0 {
                // Has previous
                let padding = NSLayoutConstraint(item: view , attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: subviews[idx - 1], attribute: NSLayoutAttribute.Bottom, multiplier:1.0, constant: 0.0)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }
        
        bezelView?.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        
        self.paddingConstraints = paddingConstraints/*.copy()*/
        self.updatePaddingConstraints()
        
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        self.updatePaddingConstraints()
        super.layoutSubviews()
    }
    
    func updatePaddingConstraints() {
        // Set padding dynamically, depending on whether the view is visible or not
        var hasVisibleAncestors = false
        
        for (_, padding) in self.paddingConstraints!.enumerate() {
            let firstView = padding.firstItem as! UIView
            let secondView = padding.secondItem as! UIView
            let firstVisible = !firstView.hidden && !CGSizeEqualToSize(firstView.intrinsicContentSize(), CGSizeZero)
            let secondVisible = !secondView.hidden && !CGSizeEqualToSize(secondView.intrinsicContentSize(), CGSizeZero)
            // Set if both views are visible or if there's a visible view on top that doesn't have padding
            // added relative to the current view yet
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? kDefaultPadding : 0.0
            hasVisibleAncestors = secondVisible || hasVisibleAncestors
        }
    }
    
    func applyPriority(priority: UILayoutPriority, toConstraints constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.priority = priority
        }
    }
    
    //MARK: Notifications
    private func updateForCurrentOrientation(animated animated: Bool) {
        // Stay in sync with the superview in any case
        if (self.superview != nil) {
            self.bounds = self.superview!.bounds
        }
        
        // Not needed on iOS 8+, compile out when the deployment target allows,
        // to avoid sharedApplication problems on extension targets
        if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000 {
            // Only needed pre iOS 8 when added to a window
            let iOS8OrLater = (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
            if iOS8OrLater || !((self.superview?.isKindOfClass(UIWindow.self)) ?? false) {
                //TODO: 此处判断有问题
                return
            }
            
            // Make extension friendly. Will not get called on extensions (iOS 8+) due to the above check.
            // This just ensures we don't get a warning about extension-unsafe API.
            
            //Class UIApplicationClass = NSClassFromString(@"UIApplication");
            //if (!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) return;
            
            let application = UIApplication.sharedApplication()
            let orientation = application.statusBarOrientation
            var radians: CGFloat?
            
            if UIInterfaceOrientationIsLandscape(orientation) {
                radians = orientation == .LandscapeLeft ? -CGFloat(M_PI_2) : CGFloat(M_PI_2)
            } else {
                radians = orientation == .PortraitUpsideDown ? CGFloat(M_PI) : 0.0
            }
            
            if animated {
                UIView.animateWithDuration(0.3, animations: { 
                    self.transform = CGAffineTransformMakeRotation(radians!)
                })
            } else {
                self.transform = CGAffineTransformMakeRotation(radians!)
            }
        }
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
        let hud: BHProgressHUD? = self.HUDForView(view)
        if let trueHud = hud {
            trueHud.removeFromSuperViewOnHide = true
            trueHud.hide(animated: animated)
            return true
        }
        
        return true
    }
    
    class func HUDForView(view: UIView) -> BHProgressHUD? {
        let subviewsEnum = view.subviews.reverse()
        for subview in subviewsEnum {
            if subview.isKindOfClass(self) {
                return subview as? BHProgressHUD
            }
        }
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
    
    deinit {
        print("BHRoundProgressView deinited.")
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
    
    deinit {
        print("BHBarProgressView deinited.")
    }
    
    //MARK: Draw
    override func drawRect(rect: CGRect) {
        
    }
}

// MARK: - BHBackgroundView
class BHBackgroundView: UIView {
    
    var style: BHProgressHUDBackgroundStyle? {
        willSet {
            var newStyle: BHProgressHUDBackgroundStyle? = newValue
            if newValue == .Blur && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0 {
                newStyle = .SolidColor
            }
            
            if style != newStyle {
                self.style = newStyle
                updateForBackgroundStyle()
            }
        }
    }
    
    var color: UIColor? {
        willSet {
            assert(color != nil, "The color should not be nil.")
            if color != newValue && color!.isEqual(newValue) {
                self.color = newValue
                updateViewForColor()
            }
        }
    }
    
    private var effectView: AnyObject?
    private var toolbar: UIToolbar?
    @available(iOS 8.0, *)
    var _effectView: UIVisualEffectView? {
        get {
            return effectView as? UIVisualEffectView
        }
        set {
            effectView = newValue
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 {
            style = .Blur
            if #available(iOS 8.0, *) {
                self.color = UIColor(white:0.8, alpha: 0.6)
            } else {
                // Fallback on earlier versions
                self.color = UIColor(white: 0.95, alpha: 0.6)
            }
        } else {
            style = .SolidColor
            color = UIColor.blackColor().colorWithAlphaComponent(0.8)
        }
        self.clipsToBounds = true
        
        updateForBackgroundStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BHBackgroundView deinited.")
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeZero
    }
    
    //MARK: Views
    func updateForBackgroundStyle() {
        if style == .Blur {
            if #available(iOS 8.0, *) {
                let effect = UIBlurEffect(style: .Light)
                let effectView = UIVisualEffectView(effect: effect)
                self.addSubview(effectView)
                effectView.frame = self.bounds
                effectView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
                self.backgroundColor = color
                self.layer.allowsGroupOpacity = false
                self.effectView = effectView;
            } else {
                // Fallback on earlier versions
                toolbar = UIToolbar(frame: CGRectInset(self.bounds, -100.0, -100.0))
                toolbar?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
                toolbar?.barTintColor = color
                toolbar?.translucent = true
                //toolbar?.barTintColor = color
                self.addSubview(toolbar!)
            }
        } else {
            if #available(iOS 8.0, *) {
                effectView!.removeFromSuperview()
                effectView = nil
            } else {
                if let _ = toolbar {
                    toolbar!.removeFromSuperview()
                    toolbar = nil
                }
            }
            backgroundColor = color
        }
    }
    
    func updateViewForColor() {
        if style == .Blur {
            if #available(iOS 8.0, *) {
                backgroundColor = color
            } else {
                toolbar!.barTintColor = color
            }
        } else {
            backgroundColor = color
        }
    }
}

// MARK: - BHProgressHUDRoundedButton
private class BHProgressHUDRoundedButton: UIButton {
    
    override var highlighted: Bool {
        willSet {
            let baseColor = self.titleColorForState(.Selected)
            backgroundColor = newValue == true ? baseColor?.colorWithAlphaComponent(0.1) : UIColor.clearColor()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BHProgressHUDRoundedButton deinited.")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Fully rounded corners
        let height = CGRectGetHeight(bounds)
        layer.cornerRadius = ceil(height / 2.0)
    }
    
    override func intrinsicContentSize() -> CGSize {
        // Only show if we have associated control events
        if self.allControlEvents().rawValue == 0 {
            return CGSizeZero
        }
        
        var size = super.intrinsicContentSize()
        // Add some side padding
        size.width += 20.0
        return size
    }
    
    override private func setTitleColor(color: UIColor?, forState state: UIControlState) {
        super.setTitleColor(color, forState: state)
        // Update related colors
//        self.highlighted = self.highlighted
        self.layer.borderColor = color?.CGColor
    }
}

