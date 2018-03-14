//
//  SettingsViewController.swift
//  DragSelectCollectionViewTestApp
//
//  Created by Haskel Ash on 3/12/18.
//  Copyright © 2018 HaskelAsh. All rights reserved.
//

import UIKit
import DragSelectCollectionView

class SettingsViewController: UITableViewController {

    //MARK: PROPERTIES

    var testAppVC: ViewController!
    @IBOutlet var hotspotsSwitch: UISwitch!

    @IBOutlet var hotspotHeightLabel: UILabel!
    @IBOutlet var hotspotHeightStepper: UIStepper!

    @IBOutlet var topHotspotOffsetLabel: UILabel!
    @IBOutlet var topHotspotOffsetStepper: UIStepper!

    @IBOutlet var bottomHotspotOffsetLabel: UILabel!
    @IBOutlet var bottomHotspotOffsetStepper: UIStepper!

    @IBOutlet var scrollVelocityLabel: UILabel!
    @IBOutlet var scrollVelocityStepper: UIStepper!

    @IBOutlet var selectionLimitLabel: UILabel!
    @IBOutlet var selectionLimitSwitch: UISwitch!
    @IBOutlet var selectionLimitStepper: UIStepper!

    @IBOutlet var loggingSwitch: UISwitch!
    @IBOutlet var disablePrimeCellsSwitch: UISwitch!

    override func viewDidLoad() {
        updateLabels()

        hotspotsSwitch.isOn = testAppVC.collectionView.showHotspots
        hotspotHeightStepper.value = Double(testAppVC.collectionView.hotspotHeight)
        topHotspotOffsetStepper.value = Double(testAppVC.collectionView.hotspotOffsetTop)
        bottomHotspotOffsetStepper.value = Double(testAppVC.collectionView.hotspotOffsetBottom)
        scrollVelocityStepper.value = Double(testAppVC.collectionView.baseAutoScrollVelocity)

        selectionLimitSwitch.isOn = testAppVC.collectionView.selectionLimit != nil
        selectionLimitStepper.isUserInteractionEnabled = selectionLimitSwitch.isOn
        selectionLimitStepper.tintColor = selectionLimitSwitch.isOn ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : .gray
        selectionLimitStepper.value = Double(testAppVC.collectionView.selectionLimit ?? 30)

        loggingSwitch.isOn = DragSelectCollectionView.logging
        disablePrimeCellsSwitch.isOn = testAppVC.disablePrimeCells
    }

    //MARK: HOTSPOTS

    @IBAction func toggleHotspots(theSwitch: UISwitch) {
        testAppVC.collectionView.showHotspots = theSwitch.isOn
    }

    @IBAction func changeHotspotHeight(stepper: UIStepper) {
        testAppVC.collectionView.hotspotHeight = CGFloat(stepper.value)
        updateLabels()
    }

    @IBAction func changeTopHotspotOffset(stepper: UIStepper) {
        testAppVC.collectionView.hotspotOffsetTop = CGFloat(stepper.value)
        updateLabels()
    }

    @IBAction func changeBottomHotspotOffset(stepper: UIStepper) {
        testAppVC.collectionView.hotspotOffsetBottom = CGFloat(stepper.value)
        updateLabels()
    }

    @IBAction func changeScrollVelocity(stepper: UIStepper) {
        let rounded = round(10 * stepper.value)/10
        testAppVC.collectionView.baseAutoScrollVelocity = CGFloat(rounded)
        updateLabels()
    }

    //MARK: SELECTION

    @IBAction func toggleSelectionLimit(theSwitch: UISwitch) {
        testAppVC.collectionView.selectionLimit =
            theSwitch.isOn ? Int(selectionLimitStepper.value) : nil
        selectionLimitStepper.isUserInteractionEnabled = theSwitch.isOn
        selectionLimitStepper.tintColor = theSwitch.isOn ? #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1) : .gray
        updateLabels()
    }

    @IBAction func changeSelectionLimit(stepper: UIStepper) {
        testAppVC.collectionView.selectionLimit = Int(stepper.value)
        updateLabels()
    }

    @IBAction func selectAll(button: UIButton) {
        testAppVC.collectionView.selectAll()
    }

    @IBAction func deselectAll(button: UIButton) {
        testAppVC.collectionView.deselectAll()
    }

    //MARK: OTHER

    @IBAction func toggleLogging(theSwitch: UISwitch) {
        DragSelectCollectionView.logging = theSwitch.isOn
    }

    @IBAction func toggleDisablePrimeCells(theSwitch: UISwitch) {
        testAppVC.disablePrimeCells = theSwitch.isOn
    }

    func updateLabels() {
        hotspotHeightLabel.text = "Hotspot Height: \(Int(testAppVC.collectionView.hotspotHeight))"
        topHotspotOffsetLabel.text = "Top Offset: \(Int(testAppVC.collectionView.hotspotOffsetTop))"
        bottomHotspotOffsetLabel.text = "Bottom Offset: \(Int(testAppVC.collectionView.hotspotOffsetBottom))"
        scrollVelocityLabel.text = "Scroll Velocity: \(testAppVC.collectionView.baseAutoScrollVelocity)"
        if let limit = testAppVC.collectionView.selectionLimit {
            selectionLimitLabel.text = "Limit: \(limit)"
        } else {
            selectionLimitLabel.text = "Limit: None"
        }
    }
}
