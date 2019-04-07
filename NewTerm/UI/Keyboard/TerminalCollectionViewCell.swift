//
//  TerminalTableViewCell.swift
//  NewTerm
//
//  Created by Adam Demasi on 11/3/19.
//  Copyright © 2019 HASHBANG Productions. All rights reserved.
//

import UIKit

class TerminalCollectionViewCell: UICollectionViewCell {

	let rowView = TerminalRowView()

	var rowIndex: Int! {
		get { return rowView.rowIndex }
		set { rowView.rowIndex = newValue }
	}
	var terminalController: TerminalController! {
		get { return rowView.terminalController }
		set { rowView.terminalController = newValue }
	}
	var fontMetrics: FontMetrics! {
		get { return rowView.fontMetrics }
		set { rowView.fontMetrics = newValue }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		rowView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(rowView)

		contentView.addCompactConstraints([
			"rowView.top = self.top",
			"rowView.right = self.right",
			"rowView.bottom = self.bottom",
			"rowView.left = self.left"
		], metrics: [:], views: [
			"self": contentView,
			"rowView": rowView
		])
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
