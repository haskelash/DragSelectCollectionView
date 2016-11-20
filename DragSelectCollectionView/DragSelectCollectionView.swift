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

    private var _nilIndexPath = IndexPath(item: -1, section: -1)
    private var _lastDraggedIndex = IndexPath(item: -1, section: -1)
    private var _initialSelection = IndexPath(item: -1, section: -1)
    private var _dragSelectActive = false
    private var _minReached = IndexPath(item: -1, section: -1)
    private var _maxReached = IndexPath(item: -1, section: -1)

    private var _hotspotHeight: CGFloat = 100
    private var _hotspotOffsetTop: CGFloat = 0
    private var _hotspotOffsetBottom: CGFloat = 0
    private var _hotspotTopBoundStart: CGFloat {
        get {
            return _hotspotOffsetTop
        }
    }
    private var _hotspotTopBoundEnd: CGFloat {
        get {
            return _hotspotOffsetTop + _hotspotHeight
        }
    }
    private var _hotspotBottomBoundStart: CGFloat {
        get {
            return bounds.size.height - _hotspotOffsetBottom - _hotspotHeight
        }
    }
    private var _hotspotBottomBoundEnd: CGFloat {
        get {
            return bounds.size.height - _hotspotOffsetBottom
        }
    }
    private var _autoScrollVelocity: CGFloat = 0

    private var _autoScrollTimer = Timer()

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


    public func setDragSelectActive(_ active: Bool, initialSelection: IndexPath) -> Bool {
        if active && _dragSelectActive {
            DragSelectCollectionView.LOG("Drag selection is already active.")
            return false
        }

        if _hotspotHeight > -1 {
            DragSelectCollectionView.LOG("CollectionView height = %d",
                args: bounds.size.height)
            DragSelectCollectionView.LOG("Hotspot top bound = %d to %d",
                args: _hotspotTopBoundStart, _hotspotTopBoundEnd)
            DragSelectCollectionView.LOG("Hotspot bottom bound = %d to %d",
                args: _hotspotBottomBoundStart, _hotspotBottomBoundEnd)

            if _debugEnabled {
                setNeedsDisplay()
            }
        }

        _lastDraggedIndex = IndexPath(item: -1, section: -1)
        _minReached = _nilIndexPath
        _maxReached = _nilIndexPath

        if delegate?.collectionView?(self, shouldSelectItemAt: initialSelection) == false {
            _dragSelectActive = false
            _initialSelection = IndexPath(item: -1, section: -1)
            _lastDraggedIndex = IndexPath(item: -1, section: -1)
            DragSelectCollectionView.LOG("Index %d is not selectable.", args: [initialSelection])
            return false
        }

        selectionManager.setSelected(indexPath: initialSelection, selected: true)
        _dragSelectActive = active
        _initialSelection = initialSelection
        _lastDraggedIndex = initialSelection
        DragSelectCollectionView.LOG("Drag selection initialized, starting at index %d.", args: [initialSelection])

//        if _fingerListener != nil {
//            _fingerListener.onDragSelectFingerAction(true)
//        }

        return true
    }

    private var _inTopHotspot = false
    private var _inBottomHotspot = false

    @objc private func autoScroll() {
        if !_autoScrollTimer.isValid { return }

        if _inTopHotspot {
            contentOffset.y -= _autoScrollVelocity
        } else if _inBottomHotspot {
            contentOffset.y += _autoScrollVelocity
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


        if !_dragSelectActive { return }

        guard let pointInBounds = event?.allTouches?.first?.location(in: self) else { return }
        let point = CGPoint(x: pointInBounds.x, y: pointInBounds.y - contentOffset.y)
        let itemPosition = getItemPosition(point: pointInBounds)

        // Check for auto-scroll hotspot
        if (_hotspotHeight > -1) {
            if point.y >= _hotspotTopBoundStart && point.y <= _hotspotTopBoundEnd {
                _inBottomHotspot = false
                if !_inTopHotspot {
                    _inTopHotspot = true
                    DragSelectCollectionView.LOG("Now in TOP hotspot")

                    _autoScrollTimer.invalidate()
                    _autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: DragSelectCollectionView.AUTO_SCROLL_DELAY,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                _autoScrollVelocity = 0.5 * (_hotspotTopBoundEnd - point.y)
                DragSelectCollectionView.LOG("Auto scroll velocity = %d", args: _autoScrollVelocity)

            } else if point.y >= _hotspotBottomBoundStart && point.y <= _hotspotBottomBoundEnd {
                _inTopHotspot = false
                if !_inBottomHotspot {
                    _inBottomHotspot = true
                    DragSelectCollectionView.LOG("Now in BOTTOM hotspot")

                    _autoScrollTimer.invalidate()
                    _autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: DragSelectCollectionView.AUTO_SCROLL_DELAY,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                _autoScrollVelocity = 0.5 * (point.y - _hotspotBottomBoundStart)
                DragSelectCollectionView.LOG("Auto scroll velocity = %d", args: _autoScrollVelocity)

            } else if _inTopHotspot || _inBottomHotspot {
                DragSelectCollectionView.LOG("Left the hotspot")
                _autoScrollTimer.invalidate()
                _inTopHotspot = false
                _inBottomHotspot = false
            }
        }

        // Drag selection logic
        if itemPosition != _nilIndexPath && _lastDraggedIndex != itemPosition {
            _lastDraggedIndex = itemPosition
            if _minReached == _nilIndexPath { _minReached = _lastDraggedIndex }
            if _maxReached == _nilIndexPath { _maxReached = _lastDraggedIndex }

            _maxReached = maxPath(a: _maxReached, b: _lastDraggedIndex)
            _minReached = minPath(a: _minReached, b: _lastDraggedIndex)

            if selectionManager != nil {
                selectionManager.selectRange(
                    from: _initialSelection,
                    to: _lastDraggedIndex,
                    min: _minReached,
                    max: _maxReached)
                DragSelectCollectionView.LOG(
                    "Selecting from: %i, to: %i, min: %i, max: %i",
                    args: [_initialSelection, _lastDraggedIndex, _minReached, _maxReached])
            }
            if _initialSelection == _lastDraggedIndex {
                _minReached = _lastDraggedIndex
                _maxReached = _lastDraggedIndex
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
        if !_dragSelectActive { return }

        _dragSelectActive = false
        _inTopHotspot = false
        _inBottomHotspot = false
        _autoScrollTimer.invalidate()
//        if _fingerListener != nil {
//            _fingerListener.onDragSelectFingerAction(false)
//        }
    }

    private var _debugEnabled = false
    private var _debugTopView = DragSelectCollectionView.newDebugView()
    private var _debugBottomView = DragSelectCollectionView.newDebugView()

    private class func newDebugView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.alpha = 0.5
        return view
    }

    public final func enableDebug() {
        if _debugEnabled { return }

        _debugEnabled = true
        updateDebugViews()

        addSubview(_debugTopView)
        addSubview(_debugBottomView)
    }

    public final func disableDebug() {
        if !_debugEnabled { return }

        _debugEnabled = false

        _debugTopView.removeFromSuperview()
        _debugBottomView.removeFromSuperview()
    }

    private func updateDebugViews() {
        if !_debugEnabled { return }
        _debugTopView.frame = CGRect(x: 0, y: contentOffset.y+_hotspotTopBoundStart, width: bounds.width, height: _hotspotHeight)
        _debugBottomView.frame = CGRect(x: 0, y: contentOffset.y+_hotspotBottomBoundStart, width: bounds.width, height: _hotspotHeight)
    }

    public override var bounds: CGRect {
        didSet {
            updateDebugViews()
        }
    }
}
