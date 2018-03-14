//
//  TestAppCell.swift
//  DragSelectCollectionViewTestApp
//
//  Created by Haskel Ash on 3/13/18.
//  Copyright © 2018 HaskelAsh. All rights reserved.
//

import UIKit

class TestAppCell: UICollectionViewCell {
    var label = UILabel()

    override func awakeFromNib() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        label.textAlignment = .center
    }

    func updateLabel(with indexPath: IndexPath) {
        label.text = "\(indexPath.section), \(indexPath.item)"
    }
}
