//
//  DragSelectionManager.swift
//  DragSelectionCollectionView
//
//  Created by Haskel Ash on 9/14/16.
//  Copyright © 2016 Haskel Ash. All rights reserved.
//

import UIKit

open class DragSelectionManager: NSObject, UICollectionViewDelegate {
    private weak var collectionView: UICollectionView!
    private(set) var selectedIndices = [IndexPath]()

    /**
     Sets a maximum number of cells that may be selected. `nil` by default.
     Setting this value to a value of zero or lower effectively disables selection.
     Setting this value to `nil` removes any upper limit to selection.
     If when setting a new value, the selection manager already has a greater number
     of cells selected, then the apporpriate number of the most recently selected cells
     will automatically be deselected.
     */
    public var maxSelectionCount: Int? {
        didSet {
            guard let max = maxSelectionCount else { return }
            var count = selectedIndices.count
            while count > max {
                let path = selectedIndices.removeLast()
                collectionView.deselectItem(at: path, animated: true)
                collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: path)
                count -= 1
            }
        }
    }

    ///Initializes a `DragSelectionManager` with the provided `UICollectionView`.
    public init(collectionView: UICollectionView) {
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
     */
    final func setSelected(_ selected: Bool, for indexPath: IndexPath) {
        if (!collectionView(collectionView, shouldSelectItemAt: indexPath) && selected)
        || (!collectionView(collectionView, shouldDeselectItemAt: indexPath) && !selected) {
            return
        }

        if selected {
            if !selectedIndices.contains(indexPath) &&
                (maxSelectionCount == nil || selectedIndices.count < maxSelectionCount!) {

                selectedIndices.append(indexPath)
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
            }
        } else if let i = selectedIndices.index(of: indexPath) {
            selectedIndices.remove(at: i)
            collectionView.deselectItem(at: indexPath, animated: true)
            collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
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
    final func toggleSelected(indexPath: IndexPath) -> Bool {
        if let i = selectedIndices.index(of:indexPath) {
            if collectionView(collectionView, shouldDeselectItemAt: indexPath) {
                selectedIndices.remove(at: i)
                collectionView.deselectItem(at: indexPath, animated: true)
                collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
                return false
            } else { return true }
        } else {
            if collectionView(collectionView, shouldSelectItemAt: indexPath) &&
            (maxSelectionCount == nil || selectedIndices.count < maxSelectionCount!) {
                selectedIndices.append(indexPath)
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
                return true
            } else { return false }
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
    final func selectRange(from: IndexPath, to: IndexPath, min: IndexPath, max: IndexPath) {
        if from.compare(to) == .orderedAscending {
            //when selecting from first selection forwards
            iterate(start: from, end: to, block: { indexPath in
                self.setSelected(true, for: indexPath)
            })
            if max != nilPath && to.compare(max) == .orderedAscending {
                //deselect items after current selection
                iterate(start: to, end: max, openLeft: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
            if min != nilPath && min.compare(from) == .orderedAscending {
                //deselect items before first selection
                iterate(start: min, end: from, openRight: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
        } else if from.compare(to) == .orderedDescending {
            //when selecting from first selection backwards
            iterate(start: to, end: from, block: { indexPath in
                self.setSelected(true, for: indexPath)
            })
            if min != nilPath && min.compare(to) == .orderedAscending {
                //deselect items before current selection
                iterate(start: min, end: to, openRight: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)
                })
            }
            if max != nilPath && from.compare(max) == .orderedAscending {
                //deselect items after first selection
                iterate(start: from, end: max, openLeft: true, block: { indexPath in
                    self.setSelected(false, for: indexPath)

                })
            }
        } else {
            //finger is back on first item, deselect everything else
            iterate(start: min, end: max, block: { indexPath in
                if indexPath != from {
                    self.setSelected(false, for: indexPath)
                }
            })
        }
    }

    private let nilPath = IndexPath(item: -1, section: -1)

    private func iterate(start: IndexPath, end: IndexPath,
                         openLeft: Bool = false, openRight: Bool = false,
                         block:(_ indexPath: IndexPath)->()) {

        var current = start
        var last = end

        if openLeft {
            if current.item + 1 < collectionView.numberOfItems(inSection: current.section) {
                current = IndexPath(item: current.item+1, section: current.section)
            } else {
                for section in current.section+1..<collectionView.numberOfSections {
                    if collectionView.numberOfItems(inSection: section) > 0 {
                        current = IndexPath(item: 0, section: section)
                        break
                    }
                }
            }
        }

        if openRight {
            if last.item > 0 {
                last = IndexPath(item: last.item-1, section: last.section)
            } else {
                for section in stride(from: last.section-1, through: 0, by: -1) {
                    if collectionView.numberOfItems(inSection: section) > 0 {
                        let items = collectionView.numberOfItems(inSection: section)
                        if items > 0 {
                            last = IndexPath(item: items-1, section: section)
                            break
                        }
                    }
                }
            }
        }

        while current.compare(last) != .orderedDescending {
            block(current)
            if collectionView.numberOfItems(inSection: current.section) > current.item + 1 {
                current = IndexPath(item: current.item+1, section: current.section)
            } else {
                current = IndexPath(item: 0, section: current.section+1)
            }
        }
    }

    final func selectAll() {
        selectedIndices.removeAll()

        //TODO: check 0 sections, or 0 items in section
        let sections = collectionView.numberOfSections
        for section in 0 ..< sections  {
            guard let items = collectionView?.numberOfItems(inSection: section) else { continue }
            for item in 0 ..< items {
                let path = IndexPath(item: item, section: section)
                if collectionView(collectionView, shouldSelectItemAt: path) {
                    selectedIndices.append(path)
                    collectionView?.selectItem(at: path, animated: true, scrollPosition: [])
                    collectionView?.delegate?.collectionView?(collectionView, didSelectItemAt: path)
                }
            }
        }
        //  notifyDataSetChanged()
        //  fireSelectionListener()
    }

    final func clearSelected() {
        selectedIndices.removeAll()
    //    notifyDataSetChanged()
    //    fireSelectionListener()
    }

    final func getSelectedCount() -> Int {
        return selectedIndices.count
    }

    public final func isIndexSelected(_ indexPath: IndexPath) -> Bool {
        return selectedIndices.contains(indexPath)
    }


    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setSelected(true, for: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        setSelected(false, for: indexPath)
    }

}
