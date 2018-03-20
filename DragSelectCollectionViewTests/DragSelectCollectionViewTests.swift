//
//  DragSelectCollectionViewTests.swift
//  DragSelectCollectionViewTests
//
//  Created by Haskel Ash on 11/19/16.
//  Copyright © 2016 HaskelAsh. All rights reserved.
//

import XCTest
@testable import DragSelectCollectionView

class DragSelectCollectionViewTests: XCTestCase {

    var collectionView: DragSelectCollectionView!

    //MARK: SET UP / TEAR DOWN

    override func setUp() {
        super.setUp()
        collectionView = DragSelectCollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.allowsMultipleSelection = true
    }

    override func tearDown() {
        collectionView = nil
        super.tearDown()
    }

    //MARK: STARTING DRAG SELECTION

    func testBeginDragSelection() {
        //given a selectable index path
        let path = IndexPath(item: 0, section: 0)

        //when I start selection with the index
        let began = collectionView.beginDragSelection(at: path)

        //then selection should begin
        XCTAssertTrue(began, "Drag selection did not start.")
    }

    //MARK: CONTINUING DRAG SELECTION

    func testContinueDragSelection() {
        //given a collection view that has started a selection event
        let path = IndexPath(item: 0, section: 0)
        collectionView.beginDragSelection(at: path)

        //when I continue that event
        collectionView.touchesMoved([], with: FakeEvent())

        //then the continued selection should be reflectd in the selected indicies
        
    }
}

class FakeEvent: UIEvent {
    override var allTouches: Set<UITouch>? {
        return [UITouch()]
    }
}
