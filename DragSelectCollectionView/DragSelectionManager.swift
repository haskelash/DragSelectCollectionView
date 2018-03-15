//
//  DragSelectionManager.swift
//  DragSelectionCollectionView
//
//  Created by Haskel Ash on 9/14/16.
//  Copyright © 2016 Haskel Ash. All rights reserved.
//

import UIKit

internal class DragSelectionManager: NSObject {
    private weak var collectionView: UICollectionView!
    private let nilPath = IndexPath(item: -1, section: -1)

    /**
     Sets a maximum number of cells that may be selected. `nil` by default.
     Setting this value to a value of zero or lower effectively disables selection.
     Setting this value to `nil` removes any upper limit to selection.
     If when setting a new value, the selection manager already has a greater number
     of cells selected, then the apporpriate number of the most recently selected cells
     will automatically be deselected.
     */
    internal var maxSelectionCount: Int? {
        didSet {
            guard let maxSelectionCount = maxSelectionCount else { return }
            guard var sorted = collectionView.indexPathsForSelectedItems?.sorted() else { return }
            while sorted.count > max(maxSelectionCount, 0) {
                let path = sorted.removeLast()
                collectionView.deselectItem(at: path, animated: true)
                collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: path)
            }
        }
    }

    ///Initializes a `DragSelectionManager` with the provided `UICollectionView`.
    internal init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    /**
     Tells the selection manager to set the cell at `indexPath` to `selected`.

     If `collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath)`
     return `false` for this `indexPath`, and `selected` is `true`, this method does nothing.

     If `collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath)`
     return `false` for this `indexPath`, and `selected` is `false`, this method does nothing.
     - Parameter indexPath: the index path to select / deselect.
     - Parameter selected: `true` to select, `false` to deselect.
     - Returns: the new selected state of the cell at `indexPath`.
     `true` for selected, `false` for deselected.
     */
    @discardableResult internal func setSelected(_ selected: Bool, for indexPath: IndexPath) -> Bool {
        if (collectionView.delegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) == false && selected)
        || (collectionView.delegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) == false && !selected) {
            return collectionView.indexPathsForSelectedItems?.contains(indexPath) == true //return state of selection, don't do anything
        }

        if selected {
            if collectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
                return true //already selected, don't do anything
            } else if maxSelectionCount == nil || collectionView.indexPathsForSelectedItems?.count ?? 0 < maxSelectionCount! {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
                return true //not already selected and doesn't exceed max, insert
            } else {
                return false //not already selected but exceeds max, don't insert
            }
        } else if collectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            collectionView.deselectItem(at: indexPath, animated: true)
            collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
            return false //selected, remove selection
        } else {
            return false //already not selected, do nothing
        }
    }

    /**
     Changes the selected state of the cell at `indexPath`.

     If `collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath)`
     return `false` for this `indexPath`, and the cell is currently deselected, this method does nothing.

     If `collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath)`
     return `false` for this `indexPath`, and the cell is currently selected, this method does nothing.
     - Parameter indexPath: the index path of the cell to toggle.
     - Returns: the new selected state of the cell at `indexPath`.
     `true` for selected, `false` for deselected.
     */
    @discardableResult internal func toggleSelected(indexPath: IndexPath) -> Bool {
        if collectionView.indexPathsForSelectedItems?.contains(indexPath) == true { //is selected, attempt remove selection
            if collectionView.delegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) == true {
                collectionView.deselectItem(at: indexPath, animated: true)
                collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
                return false
            } else { return true } //deselection disallowed, keep selected
        } else { //is unselected, attempt selection
            if collectionView.delegate?.collectionView?(collectionView, shouldSelectItemAt: indexPath) == true &&
            (maxSelectionCount == nil || collectionView.indexPathsForSelectedItems?.count ?? 0 < maxSelectionCount!) {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
                return true
            } else { return false } //selection disallowed, keep unselected
        }
    }

    /**
     Selectes all indices from `from` until `to`, inclusive.
     Deselects all indices from `min` up until the lower of `from` and `to`.
     Deselects all indice from `max` down until the greater of `from` and `to`.
     - Parameter from: the start of the selected range.
     - Parameter to: the end of the selected range.
     May be less than, equal to, or greater than `from`.
     - Parameter min: the smallest index from which to deselect up until,
     but not including, the start of the selected range.
     - Parameter max: the greates index from which to deselect down until,
     but not including, the end of the selected range.
     */
    internal func selectRange(from: IndexPath, to: IndexPath, min: IndexPath, max: IndexPath) {
        if from.compare(to) == .orderedAscending {
            //when selecting from first selection forwards
            if max != nilPath && to.compare(max) == .orderedAscending {
                //deselect items after current selection
                iterate(start: to, end: max, openLeft: true,
                        forward: false, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
            if min != nilPath && min.compare(from) == .orderedAscending {
                //deselect items before first selection
                iterate(start: min, end: from, openRight: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
            //select everything between first and current
            iterate(start: from, end: to, block: { indexPath in
                self.setSelected(true, for: indexPath)
            })
        } else if from.compare(to) == .orderedDescending {
            //when selecting from first selection backwards
            if min != nilPath && min.compare(to) == .orderedAscending {
                //deselect items before current selection
                iterate(start: min, end: to, openRight: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
            if max != nilPath && from.compare(max) == .orderedAscending {
                //deselect items after first selection
                iterate(start: from, end: max, openLeft: true,
                        forward: false, block: { indexPath in
                    self.setSelected(false, for: indexPath)

                })
            }
            //select everything between first and current
            iterate(start: to, end: from, forward: false, block: { indexPath in
                self.setSelected(true, for: indexPath)
            })
        } else {
            //finger is back on first item, select current selection
            self.setSelected(true, for: from)

            //deselect everything except current selection
            iterate(start: min, end: max, block: { indexPath in
                if indexPath != from {
                    self.setSelected(false, for: indexPath)
                }
            })
        }
    }

    /**
     Attempts to select all items, starting from the first item in the collection.
     If an item cannot be selected (decided by the `UICollectionViewDelegate`), the item is skipped.
     If `selectionLimit` is reached, this method terminates.
     The `collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)`
     method of the `UICollectionViewDelegate` is called for each selected item.
     */
    internal func selectAll() {
        let sections = collectionView.numberOfSections
        for section in 0 ..< sections  {
            let items = collectionView.numberOfItems(inSection: section)
            for item in 0 ..< items {
                if let max = maxSelectionCount,
                    collectionView.indexPathsForSelectedItems?.count ?? 0 >= max {
                    return //selection limit reached
                }
                let path = IndexPath(item: item, section: section)
                if collectionView.indexPathsForSelectedItems?.contains(path) == true {
                    continue //path is already selected
                }
                if collectionView.delegate?.collectionView?(collectionView, shouldSelectItemAt: path) == false {
                    continue //selection disallowed
                }
                collectionView?.selectItem(at: path, animated: true, scrollPosition: [])
                collectionView?.delegate?.collectionView?(collectionView, didSelectItemAt: path)
            }
        }
    }

    /**
     Deselects all selected items.
     The `collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)`
     method of the `UICollectionViewDelegate` is called for each deselected item.
     */
    internal func deselectAll() {
        guard let indices = collectionView.indexPathsForSelectedItems else { return }
        for i in stride(from: indices.count-1, through: 0, by: -1) {
            let path = indices[i]
            collectionView?.deselectItem(at: path, animated: true)
            collectionView?.delegate?.collectionView?(collectionView, didDeselectItemAt: path)
        }
    }

    private func iterate(start: IndexPath, end: IndexPath,
                         openLeft: Bool = false, openRight: Bool = false,
                         forward: Bool = true, block:(_ indexPath: IndexPath)->()) {

        var left = start
        var right = end

        if openLeft {
            if left.item + 1 < collectionView.numberOfItems(inSection: left.section) {
                left = IndexPath(item: left.item+1, section: left.section)
            } else {
                for section in left.section+1..<collectionView.numberOfSections {
                    if collectionView.numberOfItems(inSection: section) > 0 {
                        left = IndexPath(item: 0, section: section)
                        break
                    }
                }
            }
        }

        if openRight {
            if right.item > 0 {
                right = IndexPath(item: right.item-1, section: right.section)
            } else {
                for section in stride(from: right.section-1, through: 0, by: -1) {
                    let items = collectionView.numberOfItems(inSection: section)
                    if items > 0 {
                        right = IndexPath(item: items-1, section: section)
                        break
                    }
                }
            }
        }

        if forward {
            while left.compare(right) != .orderedDescending {
                block(left)
                if collectionView.numberOfItems(inSection: left.section) > left.item + 1 {
                    left = IndexPath(item: left.item+1, section: left.section)
                } else {
                    left = IndexPath(item: 0, section: left.section+1)
                }
            }
        } else {
            while right.compare(left) != .orderedAscending {
                block(right)
                if right.item > 0 {
                    right = IndexPath(item: right.item-1, section: right.section)
                } else {
                    for section in stride(from: right.section-1, through: 0, by: -1) {
                        let items = collectionView.numberOfItems(inSection: section)
                        if items > 0 {
                            right = IndexPath(item: items-1, section: section)
                            break
                        }
                    }
                }
            }
        }
    }
}
