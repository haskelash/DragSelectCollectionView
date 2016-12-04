//
//  DragSelectCollectionView.swift
//  DragSelectCollectionView
//
//  Created by Haskel Ash on 9/9/16.
//  Copyright © 2016 Haskel Ash. All rights reserved.
//

import UIKit

public class DragSelectCollectionView: UICollectionView {

    public var selectionManager: DragSelectionManager! {
        didSet {
            self.delegate = selectionManager
        }
    }

    private static let LOGGING = true
    private static let AUTO_SCROLL_DELAY: TimeInterval = 0.025

    private var nilIndexPath = IndexPath(item: -1, section: -1)
    private var lastDraggedIndex = IndexPath(item: -1, section: -1)
    private var initialSelection = IndexPath(item: -1, section: -1)
    private var dragSelectActive = false
    private var minReached = IndexPath(item: -1, section: -1)
    private var maxReached = IndexPath(item: -1, section: -1)

    private var hotspotHeight: CGFloat = 100
    private var hotspotOffsetTop: CGFloat = 0
    private var hotspotOffsetBottom: CGFloat = 0
    private var hotspotTopBoundStart: CGFloat {
        get {
            return hotspotOffsetTop
        }
    }
    private var hotspotTopBoundEnd: CGFloat {
        get {
            return hotspotOffsetTop + hotspotHeight
        }
    }
    private var hotspotBottomBoundStart: CGFloat {
        get {
            return bounds.size.height - hotspotOffsetBottom - hotspotHeight
        }
    }
    private var hotspotBottomBoundEnd: CGFloat {
        get {
            return bounds.size.height - hotspotOffsetBottom
        }
    }
    private var autoScrollVelocity: CGFloat = 0

    private var autoScrollTimer = Timer()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        allowsMultipleSelection = true
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        allowsMultipleSelection = true
    }

    private static func LOG(_ message: String, args: CVarArg...) {
        if !LOGGING { return }
        print("DragSelectCollectionView, \(String(format: message, args))")
    }


    public func setDragSelectActive(_ active: Bool, initialSelection selection: IndexPath) -> Bool {
        if active && dragSelectActive {
            DragSelectCollectionView.LOG("Drag selection is already active.")
            return false
        }

        if hotspotHeight > -1 {
            DragSelectCollectionView.LOG("CollectionView height = %d",
                args: bounds.size.height)
            DragSelectCollectionView.LOG("Hotspot top bound = %d to %d",
                args: hotspotTopBoundStart, hotspotTopBoundEnd)
            DragSelectCollectionView.LOG("Hotspot bottom bound = %d to %d",
                args: hotspotBottomBoundStart, hotspotBottomBoundEnd)

            if debugEnabled {
                setNeedsDisplay()
            }
        }

        lastDraggedIndex = IndexPath(item: -1, section: -1)
        minReached = nilIndexPath
        maxReached = nilIndexPath

        if delegate?.collectionView?(self, shouldSelectItemAt: selection) == false {
            dragSelectActive = false
            initialSelection = IndexPath(item: -1, section: -1)
            lastDraggedIndex = IndexPath(item: -1, section: -1)
            DragSelectCollectionView.LOG("Index %d is not selectable.", args: [selection])
            return false
        }

        selectionManager.setSelected(indexPath: selection, selected: true)
        dragSelectActive = active
        initialSelection = selection
        lastDraggedIndex = selection
        DragSelectCollectionView.LOG("Drag selection initialized, starting at index %d.", args: [selection])

//        if fingerListener != nil {
//            fingerListener.onDragSelectFingerAction(true)
//        }

        return true
    }

    private var inTopHotspot = false
    private var inBottomHotspot = false

    @objc private func autoScroll() {
        if !autoScrollTimer.isValid { return }

        if inTopHotspot {
            contentOffset.y -= autoScrollVelocity
        } else if inBottomHotspot {
            contentOffset.y += autoScrollVelocity
        }

        contentOffset.y = max(min(contentOffset.y, self.contentSize.height - self.bounds.size.height), 0)
    }


    func getItemPosition(point: CGPoint) -> IndexPath {
        let path = indexPathForItem(at: point)
        return path ?? IndexPath(item: -1, section: -1)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        //TODO: short circuit if no cells


        if !dragSelectActive { return }

        guard let pointInBounds = event?.allTouches?.first?.location(in: self) else { return }
        let point = CGPoint(x: pointInBounds.x, y: pointInBounds.y - contentOffset.y)
        let itemPosition = getItemPosition(point: pointInBounds)

        // Check for auto-scroll hotspot
        if (hotspotHeight > -1) {
            if point.y >= hotspotTopBoundStart && point.y <= hotspotTopBoundEnd {
                inBottomHotspot = false
                if !inTopHotspot {
                    inTopHotspot = true
                    DragSelectCollectionView.LOG("Now in TOP hotspot")

                    autoScrollTimer.invalidate()
                    autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: DragSelectCollectionView.AUTO_SCROLL_DELAY,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                autoScrollVelocity = 0.5 * (hotspotTopBoundEnd - point.y)
                DragSelectCollectionView.LOG("Auto scroll velocity = %d", args: autoScrollVelocity)

            } else if point.y >= hotspotBottomBoundStart && point.y <= hotspotBottomBoundEnd {
                inTopHotspot = false
                if !inBottomHotspot {
                    inBottomHotspot = true
                    DragSelectCollectionView.LOG("Now in BOTTOM hotspot")

                    autoScrollTimer.invalidate()
                    autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: DragSelectCollectionView.AUTO_SCROLL_DELAY,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                autoScrollVelocity = 0.5 * (point.y - hotspotBottomBoundStart)
                DragSelectCollectionView.LOG("Auto scroll velocity = %d", args: autoScrollVelocity)

            } else if inTopHotspot || inBottomHotspot {
                DragSelectCollectionView.LOG("Left the hotspot")
                autoScrollTimer.invalidate()
                inTopHotspot = false
                inBottomHotspot = false
            }
        }

        // Drag selection logic
        if itemPosition != nilIndexPath && lastDraggedIndex != itemPosition {
            lastDraggedIndex = itemPosition
            if minReached == nilIndexPath { minReached = lastDraggedIndex }
            if maxReached == nilIndexPath { maxReached = lastDraggedIndex }

            maxReached = maxPath(a: maxReached, b: lastDraggedIndex)
            minReached = minPath(a: minReached, b: lastDraggedIndex)

            if selectionManager != nil {
                selectionManager.selectRange(
                    from: initialSelection,
                    to: lastDraggedIndex,
                    min: minReached,
                    max: maxReached)
                DragSelectCollectionView.LOG(
                    "Selecting from: %i, to: %i, min: %i, max: %i",
                    args: [initialSelection, lastDraggedIndex, minReached, maxReached])
            }
            if initialSelection == lastDraggedIndex {
                minReached = lastDraggedIndex
                maxReached = lastDraggedIndex
            }
        }
    }

    //TODO: use indexpath compare func here instead
    private func maxPath(a: IndexPath, b: IndexPath) -> IndexPath {
        if a.section > b.section { return a }
        else if b.section > a.section { return b }
        else {
            if a.item >= b.item { return a }
            else { return b }
        }
    }

    private func minPath(a: IndexPath, b: IndexPath) -> IndexPath {
        if a.section < b.section { return a }
        else if b.section < a.section { return b }
        else {
            if a.item <= b.item { return a }
            else { return b }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        //TODO: short circuit if no cells
        if !dragSelectActive { return }

        dragSelectActive = false
        inTopHotspot = false
        inBottomHotspot = false
        autoScrollTimer.invalidate()
//        if fingerListener != nil {
//            fingerListener.onDragSelectFingerAction(false)
//        }
    }

    private var debugEnabled = false
    private var debugTopView = DragSelectCollectionView.newDebugView()
    private var debugBottomView = DragSelectCollectionView.newDebugView()

    private class func newDebugView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.alpha = 0.5
        return view
    }

    public final func enableDebug() {
        if debugEnabled { return }

        debugEnabled = true
        updateDebugViews()

        addSubview(debugTopView)
        addSubview(debugBottomView)
    }

    public final func disableDebug() {
        if !debugEnabled { return }

        debugEnabled = false

        debugTopView.removeFromSuperview()
        debugBottomView.removeFromSuperview()
    }

    private func updateDebugViews() {
        if !debugEnabled { return }
        debugTopView.frame = CGRect(x: 0, y: contentOffset.y+hotspotTopBoundStart, width: bounds.width, height: hotspotHeight)
        debugBottomView.frame = CGRect(x: 0, y: contentOffset.y+hotspotBottomBoundStart, width: bounds.width, height: hotspotHeight)
    }

    public override var bounds: CGRect {
        didSet {
            updateDebugViews()
        }
    }
}
