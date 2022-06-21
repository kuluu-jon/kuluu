//
//  ViewController+Embed.swift
//  ffxi iOS
//
//  Created by kuluu-jon on 5/7/22.
//
#if !os(macOS)
import UIKit

public extension UIViewController {
    func embed(
        inParent parent: UIViewController,
        withinView: UIView,
        aboveSubview: UIView? = nil
    ) {
        willMove(toParent: parent)
        if let aboveSubview = aboveSubview {
            withinView.insertSubview(self.view, aboveSubview: aboveSubview)
        } else {
            withinView.addSubview(self.view)
        }
        parent.addChild(self)

        didMove(toParent: parent)
    }

    func embed(
        inParent parent: UIViewController,
        withinView: UIView,
        belowSubview: UIView
    ) {
        willMove(toParent: parent)
        withinView.insertSubview(self.view, belowSubview: belowSubview)
        parent.addChild(self)
        didMove(toParent: parent)
    }

    func unEmbed() {
        willMove(toParent: nil)
        if let view = view {
            NSLayoutConstraint.deactivate(view.constraints)
            view.removeFromSuperview()
        }
        removeFromParent()
    }
}

#else

import AppKit

public extension NSViewController {
    func embed(inParent parent: NSViewController, withinView: NSView, aboveSubview: NSView? = nil) {
        if let aboveSubview = aboveSubview,
           let index = withinView.subviews.firstIndex(of: aboveSubview),
           index < withinView.subviews.count - 1 {
            withinView.subviews.insert(view, at: index)
        } else {
            withinView.addSubview(view)
        }
        parent.addChild(self)
    }

    func embed(inParent parent: NSViewController, withinView: NSView, belowSubview: NSView) {
        if let index = withinView.subviews.firstIndex(of: belowSubview) {
            withinView.subviews.insert(view, at: index)
        }
        parent.addChild(self)
    }

    func unEmbed() {
        NSLayoutConstraint.deactivate(view.constraints)
        view.removeFromSuperview()
        removeFromParent()
    }
}

#endif
