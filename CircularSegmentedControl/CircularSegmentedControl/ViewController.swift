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
		//cSeg.titles = SampleSegmentTitles().daysOfTheWeek
		//cSeg.titles = SampleSegmentTitles().uiKitNamedColors
		cSeg.titles = SampleSegmentTitles().alphabet(numChars: 6)
		
		//cSeg.segmentWidthsInDegrees = [30.0, 30.0, 90.0, 45.0, 75.0, 60.0]
		cSeg.segmentWidthsInDegrees = [30.0, 30.0, 40.0, 35.0, 45.0, 20.0]
		
		//cSeg.originDegrees = -45.0

		cSeg.font = .systemFont(ofSize: 15.0, weight: .light)
		cSeg.textColor = .systemBlue
		
		cSeg.addTarget(self, action: #selector(valChanged(_:)), for: .valueChanged)
	}

	@objc func valChanged(_ csc: CircularSegmentedControl) {
		print("Segment Changed:", csc.selectedSegment)
	}

}

class SampleSegmentTitles: NSObject {
	
	var daysOfTheWeek: [String] = {
		let formatter = DateFormatter()
		formatter.locale = Locale.current // Use the user's current locale
		formatter.calendar = Calendar.current // Use the user's current calendar
		return formatter.weekdaySymbols
	}()

	func alphabet(numChars: Int) -> [String] {
		return (65..<(65 + numChars)).map { String(UnicodeScalar($0)!) }
	}
	
	let uiKitNamedColors: [String] = [
		"red",
		"green",
		"blue",
		"cyan",
		"magenta",
		"yellow",
	]
	
}
