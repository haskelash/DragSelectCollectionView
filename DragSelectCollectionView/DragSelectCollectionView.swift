//
//  DragSelectCollectionView.swift
//  DragSelectCollectionView
//
//  Created by Haskel Ash on 9/9/16.
//  Copyright © 2016 Haskel Ash. All rights reserved.
//

import UIKit

/**
 A `UICollectionView` subclass that enables contiuous selection of cells while dragging.
 Use this class as you would use a regular instance of `UICollectionView`, i.e. with a
 `UICollectionViewDataSource` and a `UICollectionViewDelegate`. Call `beginDragSelection(at:)` when
 you want to start a continuous selection event starting at a particular `IndexPath`. Throughout the selection
 process, this class will ask its `delegate` if it should select / deselect each cell it encounters.
 */
public class DragSelectCollectionView: UICollectionView {

    //MARK: Public Properties

    /**
     Sets a maximum number of cells that may be selected, `nil` by default.
     Setting this value to a value of `0` or lower effectively disables selection.
     Setting this value to `nil` removes any upper limit to selection.
     If when setting a new value, the collection view already has a greater number
     of cells selected, then the apporpriate number of cells will be deselected from the end of the list.
     */
    public var selectionLimit: Int? {
        get {
            return selectionManager.maxSelectionCount
        }
        set {
            selectionManager.maxSelectionCount = newValue
        }
    }

    /**
     Height of top and bottom hotspots for auto scrolling.
     Defaults to `100`. Set this to `0` to disable auto scrolling.
     */
    public var hotspotHeight: CGFloat = 100 {
        didSet { updateHotspotViews() }
    }

    ///Padding between top of collection view and top hotspot. Defaults to `0`.
    public var hotspotOffsetTop: CGFloat = 0 {
        didSet { updateHotspotViews() }
    }

    ///Padding between bottom of collection view and bottom hotspot. Defaults to `0`.
    public var hotspotOffsetBottom: CGFloat = 0 {
        didSet { updateHotspotViews() }
    }

    /**
     Used to calculate auto scroll speed. Defaults to `0.5`.
     Auto scroll speed is calculated as `baseAutoScrollVelocity` times however many points
     into the hotspot the user has touched, per `0.025` seconds. For example, if the user has
     traversed `5` points from the middle of the screen into either of the hotspot, and this value is `0.5`,
     then the velocity will be `0.5 * 5 / 0.025 = 100` points/second.
     */
    public var baseAutoScrollVelocity: CGFloat = 0.5

    /// :nodoc:
    public override var bounds: CGRect {
        didSet {
            updateHotspotViews()
        }
    }

    ///Toggles selection and scrolling information output to console. Defaults to `false`.
    public static var logging = false

    /**
     Toggles whether to show a faded green view where the hotspots are.
     Defaults to `false`. Useful for debugging.
     */
    public var showHotspots = false { didSet {
        if showHotspots {
            if oldValue == true { return }
            updateHotspotViews()
            addSubview(hotspotTopView)
            addSubview(hotspotBottomView)
        } else {
            if oldValue == false { return }
            hotspotTopView.removeFromSuperview()
            hotspotBottomView.removeFromSuperview()
        }
    }}

    //MARK: Public Methods

    /// :nodoc:
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectionManager = DragSelectionManager(collectionView: self)
        allowsMultipleSelection = true
    }

    /// :nodoc:
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        selectionManager = DragSelectionManager(collectionView: self)
        allowsMultipleSelection = true
    }

    /**
     Attempts to begin drag selection at the provided index path.
     - Parameter selection: the index path at which to begin drag selection.
     - Returns: `false` if drag selection is alreay in progress or `selection` cannot
     be selected (decided by the `UICollectionViewDelegate`), `true` otherwise.
     */
    @discardableResult public func beginDragSelection(at selection: IndexPath) -> Bool {
        if dragSelectActive {
            DragSelectCollectionView.LOG("Drag selection is already active.")
            return false
        }

        //negative hotspotHeight denotes no hotspots, skip this part
        if hotspotHeight > -1 {
            DragSelectCollectionView.LOG("CollectionView height = %0.2f",
                                         args: bounds.size.height)
            DragSelectCollectionView.LOG("Hotspot top bound = %0.2f to %0.2f",
                                         args: hotspotTopBoundStart, hotspotTopBoundEnd)
            DragSelectCollectionView.LOG("Hotspot bottom bound = %0.2f to %0.2f",
                                         args: hotspotBottomBoundStart, hotspotBottomBoundEnd)

            if showHotspots {
                setNeedsDisplay()
            }
        }

        //if initial selection can't be selected, don't start drag selecting
        if delegate?.collectionView?(self, shouldSelectItemAt: selection) == false {
            dragSelectActive = false
            initialSelection = nilIndexPath
            lastDraggedIndex = nilIndexPath
            minReached = nilIndexPath
            maxReached = nilIndexPath
            DragSelectCollectionView.LOG("Index [%i, %i] is not selectable.",
                                            args: selection.section, selection.item)
            return false
        }

        //all good - start drag selecting
        selectionManager.setSelected(true, for: selection)
        dragSelectActive = true
        initialSelection = selection
        lastDraggedIndex = selection
        minReached = selection
        maxReached = selection
        DragSelectCollectionView.LOG("Drag selection initialized, starting at index [%i, %i].",
                                        args: selection.section, selection.item)
        return true
    }

    /// :nodoc:
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if !dragSelectActive { return }

        guard let pointInBounds = event?.allTouches?.first?.location(in: self) else { return }
        let point = CGPoint(x: pointInBounds.x, y: pointInBounds.y - contentOffset.y)
        let pathAtPoint = getItemAtPosition(point: pointInBounds)

        // Check for auto-scroll hotspot
        if (hotspotHeight > -1) {
            if point.y >= hotspotTopBoundStart && point.y <= hotspotTopBoundEnd {
                inBottomHotspot = false
                if !inTopHotspot {
                    inTopHotspot = true
                    DragSelectCollectionView.LOG("Now in TOP hotspot")

                    autoScrollTimer.invalidate()
                    autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: autoScrollDelay,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                autoScrollVelocity = baseAutoScrollVelocity * (hotspotTopBoundEnd - point.y)
                DragSelectCollectionView.LOG("Auto scroll velocity = %0.2f", args: autoScrollVelocity)

            } else if point.y >= hotspotBottomBoundStart && point.y <= hotspotBottomBoundEnd {
                inTopHotspot = false
                if !inBottomHotspot {
                    inBottomHotspot = true
                    DragSelectCollectionView.LOG("Now in BOTTOM hotspot")

                    autoScrollTimer.invalidate()
                    autoScrollTimer = Timer.scheduledTimer(
                        timeInterval: autoScrollDelay,
                        target: self, selector: #selector(autoScroll),
                        userInfo: nil, repeats: true)
                }
                autoScrollVelocity = baseAutoScrollVelocity * (point.y - hotspotBottomBoundStart)
                DragSelectCollectionView.LOG("Auto scroll velocity = %0.2f", args: autoScrollVelocity)

            } else if inTopHotspot || inBottomHotspot {
                DragSelectCollectionView.LOG("Left the hotspot")
                autoScrollTimer.invalidate()
                inTopHotspot = false
                inBottomHotspot = false
            }
        }

        // Drag selection logic
        if pathAtPoint != nilIndexPath && pathAtPoint != lastDraggedIndex {
            lastDraggedIndex = pathAtPoint

            maxReached = max(maxReached, lastDraggedIndex)
            minReached = min(minReached, lastDraggedIndex)

            selectionManager.selectRange(
                from: initialSelection,
                to: lastDraggedIndex,
                min: minReached,
                max: maxReached)
            DragSelectCollectionView.LOG(
                "Selecting from: [%i, %i], to: [%i, %i], min: [%i, %i], max: [%i, %i]",
                args: initialSelection.section, initialSelection.item,
                lastDraggedIndex.section, lastDraggedIndex.item,
                minReached.section, minReached.item,
                maxReached.section, maxReached.item)

            if initialSelection == lastDraggedIndex {
                minReached = initialSelection
                maxReached = initialSelection
            }
        }
    }

    /// :nodoc:
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if !dragSelectActive { return }

        //edge case - if user drags back to initial selection, keep that selected
        //it gets deselected by super.touchesEnded() above
        if initialSelection == lastDraggedIndex {
            selectionManager.setSelected(true, for: initialSelection)
        }

        dragSelectActive = false
        inTopHotspot = false
        inBottomHotspot = false
        autoScrollTimer.invalidate()
    }

    /**
     Attempts to select all items, starting from the first item in the collection.
     If an item cannot be selected (decided by the `UICollectionViewDelegate`), the item is skipped.
     If `selectionLimit` is reached, this method terminates.
     The `collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)`
     method of the `UICollectionViewDelegate` is called for each selected item.
     */
    public func selectAll() {
        selectionManager.selectAll()
    }

    /**
     Deselects all selected items.
     The `collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)`
     method of the `UICollectionViewDelegate` is called for each deselected item.
     */
    public func deselectAll() {
        selectionManager.deselectAll()
    }

    //MARK: PRIVATE PROPERTIES

    private var selectionManager: DragSelectionManager!

    private var dragSelectActive = false
    private var nilIndexPath = IndexPath(item: -1, section: -1)
    private var initialSelection = IndexPath(item: -1, section: -1)
    private var lastDraggedIndex = IndexPath(item: -1, section: -1)
    private var minReached = IndexPath(item: -1, section: -1)
    private var maxReached = IndexPath(item: -1, section: -1)

    private var autoScrollTimer = Timer()
    private var autoScrollVelocity: CGFloat = 0
    private let autoScrollDelay: TimeInterval = 0.025

    private var inTopHotspot = false
    private var inBottomHotspot = false
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

    //MARK: PRIVATE METHODS

    private static func LOG(_ message: String, args: CVarArg...) {
        if !logging { return }
        print("DragSelectCollectionView, " + String(format: message, arguments: args))
    }

    private func getItemAtPosition(point: CGPoint) -> IndexPath {
        let path = indexPathForItem(at: point)
        return path ?? nilIndexPath
    }

    @objc private func autoScroll() {
        if !autoScrollTimer.isValid { return }

        if inTopHotspot {
            contentOffset.y -= autoScrollVelocity
        } else if inBottomHotspot {
            contentOffset.y += autoScrollVelocity
        }

        contentOffset.y = max(min(contentOffset.y, self.contentSize.height - self.bounds.size.height), 0)
    }

    //MARK: HOTSPOT DEBUGGING

    private var hotspotTopView = DragSelectCollectionView.newHotspotView()
    private var hotspotBottomView = DragSelectCollectionView.newHotspotView()

    private class func newHotspotView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.alpha = 0.5
        return view
    }

    private func updateHotspotViews() {
        hotspotTopView.frame = CGRect(x: 0, y: contentOffset.y+hotspotTopBoundStart, width: bounds.width, height: hotspotHeight)
        hotspotBottomView.frame = CGRect(x: 0, y: contentOffset.y+hotspotBottomBoundStart, width: bounds.width, height: hotspotHeight)
    }
}
