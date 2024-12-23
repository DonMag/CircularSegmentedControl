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
		
		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 70.0, 30.0, 60.0, 40.0]
		cSeg.segmentWidthsInDegrees = [30, 30, 30, 0, 30, 30]
		cSeg.distribution = .DistributionEqual
		cSeg.titles = (0..<6).map { String($0) }
		print("tc:", cSeg.titles.count)
		cSeg.originDegrees = -45.0

		//cSeg.font = .systemFont(ofSize: 15.0, weight: .bold)
		//cSeg.textColor = .systemBlue
		
//		cSeg.ringStrokeColor = .clear
//		cSeg.separatorLinesColor = .clear
		
		cSeg.addTarget(self, action: #selector(valChanged(_:)), for: .valueChanged)
		
		//cSeg.setSelectedSegmentIndex(3, animated: true)
		
		cSeg.selectedSegmentIndex = 2
	}

	@objc func valChanged(_ csc: CircularSegmentedControl) {
		print("Segment Changed:", csc.selectedSegmentIndex)
	}

	var topIDX: Int = -1
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let t = touches.first else { return }
		let p = t.location(in: view)

		//cSeg.setSelectedSegmentIndex(6, animated: true)

		cSeg.selectedSegmentIndex = 5
		return()
		
		topIDX += 1
		if topIDX >= cSeg.titles.count {
			topIDX = -1
		}
		print("set top", topIDX)
		cSeg.topIndex = topIDX
		return()
		
		if p.x < view.frame.midX {
			cSeg.setSelectedSegmentIndex(1, animated: true)
		} else {
			cSeg.selectedSegmentIndex = 3
		}
	}
}

