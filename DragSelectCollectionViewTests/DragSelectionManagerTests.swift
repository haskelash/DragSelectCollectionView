//
//  DragSelectionManager.swift
//  DragSelectCollectionView
//
//  Created by Haskel Ash on 12/4/16.
//  Copyright © 2016 HaskelAsh. All rights reserved.
//

import XCTest
@testable import DragSelectCollectionView

class DragSelectionManagerTests: XCTestCase {

    var selectionManager: DragSelectionManager!
    var collectionView: UICollectionView!
    var mockDataSource: MockDataSource!

    //MARK: SET UP / TEAR DOWN

    override func setUp() {
        super.setUp()
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        mockDataSource = MockDataSource()
        collectionView.dataSource = mockDataSource
        selectionManager = DragSelectionManager(collectionView: collectionView)
        collectionView.allowsMultipleSelection = true
    }
    
    override func tearDown() {
        selectionManager = nil
        collectionView = nil
        mockDataSource = nil
        super.tearDown()
    }

    //MARK: SETTING MAX SELECTION


    func testSettingMaxSelectionCountLimitsSelection() {
        //given a selection manager with no selection limit
        selectionManager.maxSelectionCount = 0

        //when I set a selection limit of 5 and try to select a 6th item
        selectionManager.maxSelectionCount = 5
        (0..<6).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //then the first 5 items should be selected and the 6th item should not be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        (0..<5).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }
        XCTAssertFalse(selections.contains(IndexPath(item: 5, section: 0)),
                       "Selected indices does include [\(0), \(5)] when it should not.")
    }

    func testSettingMaxSelectionCountWhenTooManyAreSelected() {
        //given a selection manager with no selection limit and 9 selected items
        selectionManager.maxSelectionCount = nil
        (0..<9).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //when I set a selection limit of 5
        selectionManager.maxSelectionCount = 5

        //then the first 5 items should be selected and the last 4 items shoud be deselected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        (0..<5).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        (5..<9).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }
    }

    func testDisablingMaxSelection() {
        //given a selection manager with a selection limit of 5
        selectionManager.maxSelectionCount = 5

        //when I remove the selection limit and select 6 items
        selectionManager.maxSelectionCount = nil
        (0..<6).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //then all 6 items should be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        (0..<6).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }
    }

    func testSettingMaxSelectionOfZero() {
        //given a selection manager with no selection limit
        selectionManager.maxSelectionCount = nil

        //when I set a selection limit of 0 and try to select an item
        selectionManager.maxSelectionCount = 0
        selectionManager.setSelected(true, for: IndexPath(item: 0, section: 0))

        //then it should not be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        XCTAssertFalse(selections.contains(IndexPath(item: 0, section: 0)),
                       "Selected indices does include [\(0), \(0)] when it should not.")
    }

    func testSettingNegativeMaxSelection() {
        //given a selection manager with no selection limit
        selectionManager.maxSelectionCount = nil

        //when I set a selection limit of -1 and try to select an item
        selectionManager.maxSelectionCount = -1
        selectionManager.setSelected(true, for: IndexPath(item: 0, section: 0))

        //then it should not be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        XCTAssertFalse(selections.contains(IndexPath(item: 0, section: 0)),
                       "Selected indices does include [\(0), \(0)] when it should not.")
    }

    //MARK: SETTING SELECTED

    func testSetSelected() {
        //given an item that is not already selected
        let path = IndexPath(item: 0, section: 0)

        //when I select that item
        let isSelected = selectionManager.setSelected(true, for: path)

        //then it should be selected
        XCTAssert(isSelected, "Item was not selected when it should have been.")
    }

    func testSetSelectedWhenAlreadySelected() {
        //given an item that is already selected
        let path = IndexPath(item: 0, section: 0)
        selectionManager.setSelected(true, for: path)

        //when I select that item
        let isSelected = selectionManager.setSelected(true, for: path)

        //then it should be selected
        XCTAssert(isSelected, "Item was not selected when it should have been.")
    }

    func testSetSelectedWhenExeedsLimit() {
        //given an item that is not already selected
        let path = IndexPath(item: 0, section: 0)
        let otherPath = IndexPath(item: 1, section: 0)
        selectionManager.maxSelectionCount = 1
        selectionManager.setSelected(true, for: otherPath)

        //when I select that item, but it exceeds the selection limit
        let isSelected = selectionManager.setSelected(true, for: path)

        //then it should not be selected
        XCTAssert(!isSelected, "Item was selected when it should not have been.")
    }

    func testSetDeselected() {
        //given an item that is already selected
        let path = IndexPath(item: 0, section: 0)
        selectionManager.setSelected(true, for: path)

        //when I deselect that item
        let isSelected = selectionManager.setSelected(false, for: path)

        //then it should be deselected
        XCTAssert(!isSelected, "Item was selected when it should not have been.")
    }

    func testDeselectedWhenAlreadyDeselected() {
        //given an item that is already deselected
        let path = IndexPath(item: 0, section: 0)
        selectionManager.setSelected(false, for: path)

        //when I deselect that item
        let isSelected = selectionManager.setSelected(false, for: path)

        //then it should be deselected
        XCTAssert(!isSelected, "Item was selected when it should not have been.")
    }

    //MARK: TOGGLING SELECTION

    //MARK: SELECTING RANGE

    func testSelectRangeAscending() {
        //given all items except the range [10, 13] are already selected
        (0..<10).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }
        (14..<20).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //when I select, in the forward direction, the range [10, 13] with a min of 5 and a max of 17
        let from = IndexPath(item: 10, section: 0)
        let to = IndexPath(item: 13, section: 0)
        let min = IndexPath(item: 5, section: 0)
        let max = IndexPath(item: 17, section: 0)
        selectionManager.selectRange(from: from, to: to, min: min, max: max)

        //then the range [10, 13] should be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        (from.item...to.item).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        //and anything in the range [5, 10), and in the range (13, 17] should be deselected
        (min.item..<from.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        (to.item+1...max.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        //and anthing before 5 and 17 should still be selected
        (0..<min.item).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        (max.item+1..<collectionView.numberOfItems(inSection: 0)).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }
    }

    func testSelectRangeDescending() {
        //given all items except the range [10, 13] are already selected
        (0..<10).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }
        (14..<20).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //when I select, in the backward direction, the range [10, 13] with a min of 5 and a max of 17
        let from = IndexPath(item: 13, section: 0)
        let to = IndexPath(item: 10, section: 0)
        let min = IndexPath(item: 5, section: 0)
        let max = IndexPath(item: 17, section: 0)
        selectionManager.selectRange(from: from, to: to, min: min, max: max)

        //then the range [10, 13] should be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        (to.item...from.item).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        //and anything in the range [5, 10), and in the range (13, 17] should be deselected
        (min.item..<to.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        (from.item+1...max.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        //and anthing before 5 and 17 should still be selected
        (0..<min.item).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        (max.item+1..<collectionView.numberOfItems(inSection: 0)).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }
    }

    func testSelectRangeSame() {
        //given all items except the range [10, 10] are already selected
        (0..<10).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }
        (11..<20).forEach() {
            selectionManager.setSelected(true, for: IndexPath(item: $0, section: 0))
        }

        //when I select the range [10, 10] with a min of 5 and a max of 17
        let from = IndexPath(item: 10, section: 0)
        let to = IndexPath(item: 10, section: 0)
        let min = IndexPath(item: 5, section: 0)
        let max = IndexPath(item: 17, section: 0)
        selectionManager.selectRange(from: from, to: to, min: min, max: max)

        //then the range [10, 10] should be selected
        guard let selections = collectionView.indexPathsForSelectedItems else {
            XCTFail("Selected indices is empty.")
            return
        }

        XCTAssert(selections.contains(IndexPath(item: 10, section: 0)),
                  "Selected indices does not include [\(0), \(10)].")

        //and anything in the range [5, 10), and in the range (10, 17] should be deselected
        (min.item..<from.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        (to.item+1...max.item).forEach() {
            XCTAssertFalse(selections.contains(IndexPath(item: $0, section: 0)),
                           "Selected indices does include [\(0), \($0)] when it should not.")
        }

        //and anthing before 5 and 17 should still be selected
        (0..<min.item).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }

        (max.item+1..<collectionView.numberOfItems(inSection: 0)).forEach() {
            XCTAssert(selections.contains(IndexPath(item: $0, section: 0)),
                      "Selected indices does not include [\(0), \($0)].")
        }
    }

    //MARK: SELECTING ALL

    //MARK: DESELECTING ALL
}

class MockDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}

