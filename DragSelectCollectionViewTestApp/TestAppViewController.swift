//
//  ViewController.swift
//  DragSelectCollectionViewTestApp
//
//  Created by Haskel Ash on 11/19/16.
//  Copyright © 2016 HaskelAsh. All rights reserved.
//

import UIKit
import DragSelectCollectionView

class TestAppViewController: UIViewController {

    //MARK: PROPERTIES

    @IBOutlet var collectionView: DragSelectCollectionView!
    @IBOutlet var countLabel: UIBarButtonItem!
    var selectionCount = 0

    //MARK: FUNCTIONS

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.presentationController?.delegate = self
        (segue.destination as? SettingsViewController)?.testAppVC = self
    }

    @IBAction func longPress(with gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        let point = gr.location(in: collectionView)
        if let path = collectionView.indexPathForItem(at: point) {
            if !collectionView.beginDragSelection(at: path) {
                print("Drag selection could not be activated")
            }
        }
    }

    var disablePrimeCells = false {
        didSet {
            if disablePrimeCells == false { return }
            for path in collectionView.indexPathsForSelectedItems ?? [] {
                if !path.item.isInPrimes() { continue }
                collectionView.deselectItem(at: path, animated: true)
                collectionView.delegate?.collectionView?(collectionView, didDeselectItemAt: path)
            }
        }
    }
}

//MARK: UICollectionViewDataSource

extension TestAppViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                     withReuseIdentifier: "testAppHeader", for: indexPath) as! TestAppHeader
        header.updateLabel(with: indexPath.section)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "testAppCell", for: indexPath) as! TestAppCell
        cell.updateLabel(with: indexPath)
        cell.backgroundColor = cell.isSelected ? #colorLiteral(red: 1, green: 0.5411764706, blue: 0.8509803922, alpha: 1) : #colorLiteral(red: 0.4, green: 0.8, blue: 1, alpha: 1)
        return cell
    }
}

//MARK: UICollectionViewDelegate

extension TestAppViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.backgroundColor = cell.isSelected ? #colorLiteral(red: 1, green: 0.5411764706, blue: 0.8509803922, alpha: 1) : #colorLiteral(red: 0.4, green: 0.8, blue: 1, alpha: 1)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.indexPathsForSelectedItems?.count ?? 0 >= self.collectionView.selectionLimit ?? Int.max { return false }
        return !disablePrimeCells || !indexPath.item.isInPrimes()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = #colorLiteral(red: 1, green: 0.5411764706, blue: 0.8509803922, alpha: 1)
        selectionCount += 1
        countLabel.title = "Selected: \(selectionCount)"
        animate(cell: cell)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = #colorLiteral(red: 0.4, green: 0.8, blue: 1, alpha: 1)
        selectionCount -= 1
        countLabel.title = "Selected: \(selectionCount)"
        animate(cell: cell)
    }

    func animate(cell: UICollectionViewCell?) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1,
                       initialSpringVelocity: 0, options: [], animations: {
            cell?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            cell?.alpha = 0.8
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1,
                           initialSpringVelocity: 0, options: [], animations: {
                cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
                cell?.alpha = 1
            }, completion: nil)
        })
    }
}

//MARK: UICollectionViewDelegateFlowLayout

extension TestAppViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let insets = self.collectionView(collectionView, layout: collectionViewLayout,
                                         insetForSectionAt: indexPath.section)
        let spacing = self.collectionView(collectionView, layout: collectionViewLayout,
                                          minimumInteritemSpacingForSectionAt: indexPath.section)
        let numberOfCells: CGFloat = 5
        let availableWidth = collectionView.bounds.width - insets.left - insets.right
        let cellWidth = (availableWidth - ((numberOfCells-1) * spacing)) / numberOfCells
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

extension TestAppViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

//MARK: OTHER

let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41,
              43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
extension Int {
    func isInPrimes() -> Bool {
        return primes.contains(self)
    }
}
