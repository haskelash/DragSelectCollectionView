//
//  ViewController.swift
//  DragSelectCollectionViewTestApp
//
//  Created by Haskel Ash on 11/19/16.
//  Copyright © 2016 HaskelAsh. All rights reserved.
//

import UIKit
import DragSelectCollectionView

class ViewController: UIViewController, UICollectionViewDataSource {

    @IBOutlet var collectionView: DragSelectCollectionView!

    override func viewDidLoad() {
        collectionView.selectionManager = SampleSelectionManager(collectionView: collectionView)
        collectionView.enableDebug()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 36
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        cell.setLabelText(str: "\(indexPath.section), \(indexPath.item)")
        if self.collectionView.selectionManager.isIndexSelected(indexPath) {
            cell.backgroundColor = UIColor(red: 1.0, green: 0.54, blue: 0.85, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        }
        return cell
    }

    @IBAction func longPress(with gr: UILongPressGestureRecognizer) {
        if gr.state == .began {
            let point = gr.location(in: collectionView)
            if let path = collectionView.indexPathForItem(at: point) {
                if !collectionView.setDragSelectActive(true, initialSelection: path) {
                    print("Drag selection could not be activated")
                }
            }
        }
    }
}


class Cell: UICollectionViewCell {
    var label: UILabel

    required init?(coder aDecoder: NSCoder) {
        label = UILabel()

        super.init(coder: aDecoder)

        label.frame = bounds
        label.textAlignment = .center
        addSubview(label)
    }

    func setLabelText(str: String) {
        label.text = str
    }
}

class SampleSelectionManager: DragSelectionManager {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item != 20
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(red: 1.0, green: 0.54, blue: 0.85, alpha: 1.0)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didDeselectItemAt: indexPath)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
    }
}
