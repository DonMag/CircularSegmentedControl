//
//  Segment.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

import UIKit

class Segment: NSObject {
	var title: String = "A"
	var startAngleInDegrees: Double = 0.0
	var endAngleInDegrees: Double = 0.0
	var path: UIBezierPath = UIBezierPath()
}
