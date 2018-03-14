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

    //MARK: TOGGLING SELECTION

    //MARK: SELECTING RANGE

    //MARK: SELECTING ALL

    //MARK: DESELECTING ALL
}

class MockDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}

