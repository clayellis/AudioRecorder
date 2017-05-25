//
//  UIView+Extras.swift
//  Clay Ellis
//  gist.github.com/clayellis/0cf1b1092b6a08cb4c5b2da9abee5ed9
//

import UIKit

extension UIView {
    
    // MARK: - NSLayoutConstraint Convenience Methods
    
    func addAutoLayoutSubview(_ subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func insertAutoLayoutSubview(_ view: UIView, at index: Int) {
        insertSubview(view, at: index)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func insertAutoLayoutSubview(_ view: UIView, belowSubview: UIView) {
        insertSubview(view, belowSubview: belowSubview)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func insertAutoLayoutSubview(_ view: UIView, aboveSubview: UIView) {
        insertSubview(view, aboveSubview: aboveSubview)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: Layout Macros
    
    func fillSuperview() {
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ])
    }
    
    func fillSuperviewLayoutMargins() {
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo: superview.leftMargin),
            rightAnchor.constraint(equalTo: superview.rightMargin),
            topAnchor.constraint(equalTo: superview.topMargin),
            bottomAnchor.constraint(equalTo: superview.bottomMargin)
            ])
    }
    
    func centerInSuperview() {
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            centerYAnchor.constraint(equalTo: superview.centerYAnchor)
            ])
    }
    
    func centerInSuperviewLayoutMargins() {
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: superview.centerXMargin),
            centerYAnchor.constraint(equalTo: superview.centerYMargin)
            ])
    }
    
    // MARK: Layout Margins Guide Shortcut
    
    var leftMargin: NSLayoutXAxisAnchor {
        return layoutMarginsGuide.leftAnchor
    }
    
    var rightMargin: NSLayoutXAxisAnchor {
        return layoutMarginsGuide.rightAnchor
    }
    
    var centerXMargin: NSLayoutXAxisAnchor {
        return layoutMarginsGuide.centerXAnchor
    }
    
    var widthMargin: NSLayoutDimension {
        return layoutMarginsGuide.widthAnchor
    }
    
    var topMargin: NSLayoutYAxisAnchor {
        return layoutMarginsGuide.topAnchor
    }
    
    var bottomMargin: NSLayoutYAxisAnchor {
        return layoutMarginsGuide.bottomAnchor
    }
    
    var centerYMargin: NSLayoutYAxisAnchor {
        return layoutMarginsGuide.centerYAnchor
    }
    
    var heightMargin: NSLayoutDimension {
        return layoutMarginsGuide.heightAnchor
    }
    
    // MARK: Subview Retrieval
    
    func subviewWithClassName(_ className: String) -> UIView? {
        for subview in subviews {
            if type(of: subview).description() == className {
                return subview
            } else if let found = subview.subviewWithClassName(className) {
                return found
            }
        }
        return nil
    }
    
    func subviewWithClassType(_ classType: AnyClass) -> UIView? {
        for subview in subviews {
            if subview.isKind(of: classType) {
                return subview
            } else if let found = subview.subviewWithClassType(classType) {
                return found
            }
        }
        return nil
    }
    
    func indexOfSubview(_ subview: UIView) -> Int? {
        return subviews.index(of: subview)
    }
    
    func exchangeSubview(_ subviewOne: UIView, withSubview subviewTwo: UIView) {
        if let subviewOneIndex = indexOfSubview(subviewOne),
            let subviewTwoIndex = indexOfSubview(subviewTwo) {
            self.exchangeSubview(at: subviewOneIndex, withSubviewAt: subviewTwoIndex)
        }
    }
    
    var currentFirstResponder: UIResponder? {
        if isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }
        
        return nil
    }
    
    // Useful, but commenting out to avoid warnings
    //    func printRecursiveDescription() {
    //        print(perform("recursiveDescription"))
    //    }
    
    //    func printAutolayoutTrace() {
    //        print(perform("_autolayoutTrace"))
    //    }
    
}

extension NSLayoutDimension {
    
    // Anchor
    
    func constraint(equalTo anchor: NSLayoutDimension, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(equalTo: anchor)
        cst.priority = p
        return cst
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(lessThanOrEqualTo: anchor)
        cst.priority = p
        return cst
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(greaterThanOrEqualTo: anchor)
        cst.priority = p
        return cst
    }
    
    // Constant
    
    func constraint(equalToConstant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(equalToConstant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(greaterThanOrEqualToConstant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(greaterThanOrEqualToConstant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(lessThanOrEqualToConstant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(lessThanOrEqualToConstant: c)
        cst.priority = p
        return cst
    }
    
    // Anchor, Constant
    
    func constraint(equalTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(equalTo: anchor, constant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(lessThanOrEqualTo: anchor, constant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(greaterThanOrEqualTo: anchor, constant: c)
        cst.priority = p
        return cst
    }
    
    // Anchor, Multiplier
    
    func constraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(equalTo: anchor, multiplier: m)
        cst.priority = p
        return cst
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(greaterThanOrEqualTo: anchor, multiplier: m)
        cst.priority = p
        return cst
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(lessThanOrEqualTo: anchor, multiplier: m)
        cst.priority = p
        return cst
    }
    
    // Anchor, Multiplier, Constant
    
    func constraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(equalTo: anchor, multiplier: m, constant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(greaterThanOrEqualTo: anchor, multiplier: m, constant: c)
        cst.priority = p
        return cst
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: Float) -> NSLayoutConstraint {
        let cst = constraint(lessThanOrEqualTo: anchor, multiplier: m, constant: c)
        cst.priority = p
        return cst
    }
    
}

enum LayoutPriority {
    case required
    case high
    case low
    case fittingSizeLevel
    case custom(priority: Float)
    
    var floatValue: Float {
        switch self {
        case .required: return UILayoutPriorityRequired
        case .high: return UILayoutPriorityDefaultHigh
        case .low: return UILayoutPriorityDefaultLow
        case .fittingSizeLevel: return UILayoutPriorityFittingSizeLevel
        case .custom(let priority): return priority
        }
    }
}

extension NSLayoutDimension {
    
    // Anchor
    
    func constraint(equalTo anchor: NSLayoutDimension, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(equalTo: anchor, priority: p.floatValue)
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(lessThanOrEqualTo: anchor, priority: p.floatValue)
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(greaterThanOrEqualTo: anchor, priority: p.floatValue)
    }
    
    // Constant
    
    func constraint(equalToConstant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(equalToConstant: c, priority: p.floatValue)
    }
    
    func constraint(greaterThanOrEqualToConstant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(greaterThanOrEqualToConstant: c, priority: p.floatValue)
    }
    
    func constraint(lessThanOrEqualToConstant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(lessThanOrEqualToConstant: c, priority: p.floatValue)
    }
    
    // Anchor, Constant
    
    func constraint(equalTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(equalTo: anchor, constant: c, priority: p.floatValue)
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(lessThanOrEqualTo: anchor, constant: c, priority: p.floatValue)
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(greaterThanOrEqualTo: anchor, constant: c, priority: p.floatValue)
    }
    
    // Anchor, Multiplier
    
    func constraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(equalTo: anchor, multiplier: m, priority: p.floatValue)
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(greaterThanOrEqualTo: anchor, multiplier: m, priority: p.floatValue)
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(lessThanOrEqualTo: anchor, multiplier: m, priority: p.floatValue)
    }
    
    // Anchor, Multiplier, Constant
    
    func constraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(equalTo: anchor, multiplier: m, constant: c, priority: p.floatValue)
    }
    
    func constraint(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(greaterThanOrEqualTo: anchor, multiplier: m, constant: c, priority: p.floatValue)
    }
    
    func constraint(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat, priority p: LayoutPriority) -> NSLayoutConstraint {
        return constraint(lessThanOrEqualTo: anchor, multiplier: m, constant: c, priority: p.floatValue)
    }
    
}
