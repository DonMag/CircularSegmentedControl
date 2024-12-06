//
//  ViewController.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/6/24.
//

import UIKit

class ViewController: UIViewController {

	let cSeg = CircularSegmentedControl()

	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .systemBackground

		let g = view.safeAreaLayoutGuide
		
		cSeg.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(cSeg)
		
		NSLayoutConstraint.activate([
			cSeg.topAnchor.constraint(equalTo: g.topAnchor, constant: 40.0),
			cSeg.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 40.0),
			cSeg.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -40.0),
			cSeg.heightAnchor.constraint(equalTo: cSeg.widthAnchor),
		])

		let formatter = DateFormatter()
		formatter.locale = Locale.current // Use the user's current locale
		formatter.calendar = Calendar.current // Use the user's current calendar
		cSeg.titles = formatter.weekdaySymbols
		cSeg.font = .systemFont(ofSize: 13.0, weight: .light)
		cSeg.textColor = .systemBlue
	}


}

