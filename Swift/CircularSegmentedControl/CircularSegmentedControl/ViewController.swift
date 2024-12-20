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

		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 90.0, 45.0, 20.0, 30.0]

		// sample segment titles
		cSeg.titles = SampleSegmentTitles().daysOfTheWeek
		//cSeg.titles = SampleSegmentTitles().uiKitNamedColors
		cSeg.titles = SampleSegmentTitles().alphabet(numChars: 6)
		
		//cSeg.titles = ["A", "B", "Long Title", "C"]
		//cSeg.distribution = .proportional
		
		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 90.0, 45.0, 75.0, 60.0]
		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 40.0, 35.0, 45.0, 20.0]
		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 70.0, 30.0, 40.0, 35.0, 45.0, 20.0]
		
		cSeg.segmentWidthsInDegrees = [30.0, 30.0, 70.0, 30.0, 60.0, 40.0]
		cSeg.segmentWidthsInDegrees = [30.0]
		//cSeg.distribution = .equal
		
		//cSeg.originDegrees = -45.0

		cSeg.font = .systemFont(ofSize: 15.0, weight: .bold)
		//cSeg.textColor = .systemBlue
		
		cSeg.addTarget(self, action: #selector(valChanged(_:)), for: .valueChanged)
		
	}

	@objc func valChanged(_ csc: CircularSegmentedControl) {
		print("Segment Changed:", csc.selectedSegmentIndex)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let t = touches.first else { return }
		let p = t.location(in: view)
		if p.x < view.frame.midX {
			cSeg.setSelectedSegmentIndex(1, animated: true)
		} else {
			cSeg.selectedSegmentIndex = 3
		}
	}
}

