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

    var collectionView: UICollectionView!
    var dataSource: MockDataSource!
    static var exp: XCTestExpectation!

    override func setUp() {
        super.setUp()
        collectionView = UICollectionView(frame: CGRect.zero,
                                          collectionViewLayout: UICollectionViewLayout())
        dataSource = MockDataSource()
        collectionView.dataSource = dataSource
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSetSelected() {
        //given a selection manager and an index path
        let selectionManager = SelectionManagerExpectingCalls(collectionView: collectionView)
        collectionView.delegate = selectionManager
        let path = IndexPath(item: 3, section: 2)
        type(of: self).exp = expectation(description: "Method didSelectItemAtIndexPath: should be called.")

        //when the selection manager selects that path
        selectionManager.setSelected(true, for: path)

        //then selectedIndicies should contain that path and the delegate method should be called
        XCTAssert(selectionManager.selectedIndices.contains(path))
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSetSelectedAgain() {
        //given a selection manager and an index path that has already been selected
        let selectionManager = SelectionManagerExpectingCalls(collectionView: collectionView)
        collectionView.delegate = nil
        let path = IndexPath(item: 3, section: 2)
        selectionManager.setSelected(true, for: path)

        //when the selection manager selects that path again
        collectionView.delegate = SelectionManagerNotExpectingCalls(collectionView: collectionView)
        selectionManager.setSelected(true, for: path)

        //then selectedIndicies should contain that path and the delegate method should not be called
        XCTAssert(selectionManager.selectedIndices.contains(path))
    }
}

class SelectionManagerExpectingCalls: DragSelectionManager {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        DragSelectionManagerTests.exp.fulfill()
    }
}

class SelectionManagerNotExpectingCalls: DragSelectionManager {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        XCTFail("Method didSelectItemAtIndexPath: was called when it shouldn't be.")
    }
}

class MockDataSource: NSObject, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
