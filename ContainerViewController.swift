//
//  ContainerViewController.swift
//  SlideOutNavigation
//
//  Created by Harsh Fadnavis on 09/00/2016.
//  Copyright (c) 2014 James Frost. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case bothCollapsed
    case leftPanelExpanded
    case rightPanelExpanded
}

class ContainerViewController: UIViewController {
    
    var centerNavigationController: UINavigationController!
    var homeMainViewController: HomeMainViewController!
    var homeTabBarController: UITabBarController!
    var channelIdFromNotification = ""
    var channelNameFromNotification = ""
    
    var currentState: SlideOutState = .bothCollapsed {
        didSet {
            let shouldShowShadow = currentState != .bothCollapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }
    
    var leftViewController: SidePanelViewController?
    var rightViewController: SidePanelViewController?
    
    let centerPanelExpandedOffset: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        homeMainViewController = UIStoryboard.centerViewController()
//        homeMainViewController.centerviewdelegate = self

        // wrap the centerViewController in a navigation controller, so we can push views to it
        // and display bar button items in the navigation bar
        //centerNavigationController = UINavigationController(rootViewController: homeMainViewController)
        centerNavigationController = UIStoryboard.centerNavController()                        
        
        homeMainViewController = centerNavigationController?.viewControllers.first as? HomeMainViewController
        if(self.channelIdFromNotification != "") {
            homeMainViewController.channelIdFromNotification = self.channelIdFromNotification
            homeMainViewController.channelNameFromNotification = self.channelNameFromNotification
        }
        
        homeMainViewController.centerviewdelegate = self
        //centerNavigationController = homeMainViewController.navigationController
        view.addSubview(centerNavigationController.view)
        addChildViewController(centerNavigationController)
        
//        centerNavigationController.navigationBar.barStyle = UIBarStyle.Black
//        centerNavigationController.navigationBar.tintColor = UIColor.whiteColor()
//        homeTabBarController = UITabBarController()
//        homeTabBarController.delegate = self
//        view.addSubview(homeTabBarController.view)
//        addChildViewController(homeTabBarController)
        
        
        centerNavigationController.didMove(toParentViewController: self)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ContainerViewController.handlePanGesture(_:)))
        centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
        //self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - Container View Controller
    override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        return true
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
    
    
    
}


// MARK: CenterViewController delegate

extension ContainerViewController: CenterViewControllerDelegate {
    
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
            homeMainViewController.pageMenu?.view.isUserInteractionEnabled = false
        } else {
            homeMainViewController.pageMenu?.view.isUserInteractionEnabled = true
        }
        
        animateLeftPanel(notAlreadyExpanded)
    }
    
    func toggleRightPanel() {
        let notAlreadyExpanded = (currentState != .rightPanelExpanded)
        
        if notAlreadyExpanded {
            addRightPanelViewController()
            homeMainViewController.pageMenu?.view.isUserInteractionEnabled = false
        } else {
            homeMainViewController.pageMenu?.view.isUserInteractionEnabled = true
        }
        
        animateRightPanel(notAlreadyExpanded)
    }
    
    func collapseSidePanels() {
        switch (currentState) {
        case .rightPanelExpanded:
            toggleRightPanel()
        case .leftPanelExpanded:
            toggleLeftPanel()
        default:
            break
        }
    }
    
    func removeLeftPanelViewController() {
        leftViewController?.removeFromParentViewController()
    }
    
    func removeRightPaneLViewController() {
        rightViewController?.removeFromParentViewController()
    }
    
    func removeCenterViewController() {
        homeMainViewController.removeFromParentViewController()
        centerNavigationController.removeFromParentViewController()
    }
    
    
    func addLeftPanelViewController() {
        if (leftViewController == nil) {
            leftViewController = UIStoryboard.leftViewController()
            leftViewController!.menu = Menu.allMenu()
            
            addChildSidePanelController(leftViewController!)
        }
    }
    
    func addChildSidePanelController(_ sidePanelController: SidePanelViewController) {
        sidePanelController.delegate = homeMainViewController
        
        view.insertSubview(sidePanelController.view, at: 0)
        
        addChildViewController(sidePanelController)
        sidePanelController.didMove(toParentViewController: self)
    }
    
    func addRightPanelViewController() {
        if (rightViewController == nil) {
            rightViewController = UIStoryboard.rightViewController()
            rightViewController!.menu = Menu.allLanguages()
            
            addChildSidePanelController(rightViewController!)
        }
    }
    
    func animateLeftPanel(_ shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(centerNavigationController.view.frame.width - centerPanelExpandedOffset)
            self.homeMainViewController.pageMenu?.view.isUserInteractionEnabled = false
        } else {
            animateCenterPanelXPosition(0) { finished in
                self.currentState = .bothCollapsed
                if self.leftViewController == nil {
                    return
                }
                self.leftViewController!.view.removeFromSuperview()
                self.leftViewController = nil;
                self.homeMainViewController.pageMenu?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func animateCenterPanelXPosition(_ targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.centerNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
    func animateRightPanel(_ shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .rightPanelExpanded
            
            animateCenterPanelXPosition(-centerNavigationController.view.frame.width + centerPanelExpandedOffset)
            self.homeMainViewController.pageMenu?.view.isUserInteractionEnabled = false
        } else {
            animateCenterPanelXPosition(0) { _ in
                self.currentState = .bothCollapsed
                if self.rightViewController == nil {
                    return
                }
                self.rightViewController!.view.removeFromSuperview()
                self.rightViewController = nil;
                self.homeMainViewController.pageMenu?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func showShadowForCenterViewController(_ shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            centerNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            centerNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
}

extension ContainerViewController: UIGestureRecognizerDelegate {
    // MARK: Gesture recognizer
    
    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        if(self.centerNavigationController.topViewController is HomeMainViewController) {
            let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: view).x > 0)
            
            switch(recognizer.state) {
            case .began:
                if (currentState == .bothCollapsed) {
                    if (gestureIsDraggingFromLeftToRight) {
                        addLeftPanelViewController()
                    }
                    else {
                        addRightPanelViewController()
                    }
                    
                    showShadowForCenterViewController(true)
                    homeMainViewController.pageMenu?.view.isUserInteractionEnabled = false
                } else {
                    homeMainViewController.pageMenu?.view.isUserInteractionEnabled = true
                }
            case .changed:
                recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translation(in: view).x
                recognizer.setTranslation(CGPoint.zero, in: view)
            case .ended:
                if (leftViewController != nil) {
                    // animate the side panel open or closed based on whether the view has moved more or less than halfway
                    let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                    animateLeftPanel(hasMovedGreaterThanHalfway)
                } else if (rightViewController != nil) {
                    let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
                    animateRightPanel(hasMovedGreaterThanHalfway)
                }
            default:
                break
            }
        }
    }
}

private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }
    
    class func leftViewController() -> SidePanelViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "LeftMenuViewController") as? SidePanelViewController
    }
    
    class func centerViewController() -> HomeMainViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "HomeMainViewController") as? HomeMainViewController
    }
    
    class func rightViewController() -> SidePanelViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "languageViewScene") as? SidePanelViewController
    }
    
    class func centerNavController() -> UINavigationController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "centerNav") as? UINavigationController
    }
    
}
