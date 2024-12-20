//
//  CircularSegmentedControl.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/6/24.
//

import UIKit

class CircularSegmentedControl: UIControl {
	
	enum Distribution {
		case equal, proportional, userDefined
	}
	public var distribution: Distribution = .equal {
		didSet {
			setMyNeedsLayout()
		}
	}
	public var font: UIFont = .systemFont(ofSize: 16) {
		didSet {
			if distribution == .proportional {
				setMyNeedsLayout()
			} else {
				for v in arcTexts {
					v.font = font
				}
			}
		}
	}
	public var textColor: UIColor = .black {
		didSet {
			for v in arcTexts {
				v.textColor = textColor
			}
		}
	}
	public var segmentColor: UIColor = .white {
		didSet {
			segmentLayer.fillColor = segmentColor.cgColor
		}
	}
	public var segmentShadowOpacity: Float = 0.2 {
		didSet {
			segmentLayer.shadowOpacity = segmentShadowOpacity
		}
	}
	public var ringFillColor: UIColor = UIColor(white: 0.95, alpha: 1.0) {
		didSet {
			ringLayer.fillColor = ringFillColor.cgColor
		}
	}
	public var ringStrokeColor: UIColor = UIColor(white: 0.8, alpha: 1.0) {
		didSet {
			linesLayer.strokeColor = ringStrokeColor.cgColor
		}
	}
	
	public var titles: [String] = [] { didSet { setMyNeedsLayout() } }
	
	public var segmentWidthsInDegrees: [Double] = [] {
		didSet {
			distribution = .userDefined
			setMyNeedsLayout()
		}
	}
	
	// Duration of segment animation in seconds
	public var animationDuration: TimeInterval = 0.3
	
	// angle for start of first segment
	public var originDegrees: Double = 0.0 { didSet { setMyNeedsLayout() } }
	
	// width of ring
	public var ringWidth: CGFloat = 40.0 { didSet { setMyNeedsLayout() } }
	
	// radius of segment corners
	public var cornerRadius: CGFloat = 6.0 { didSet { setMyNeedsLayout() } }
	
	public var selectedSegmentIndex: Int {
		set {
			updateSegment(newValue)
		}
		get {
			return m_selectedSegment
		}
	}
	public func setSelectedSegmentIndex(_ n: Int, animated: Bool) {
		if animated, m_selectedSegment > -1 {
			animateSegment(from: m_selectedSegment, to: n)
		} else {
			updateSegment(n)
		}
		m_selectedSegment = n
	}
	
	// private properties
	private var m_selectedSegment: Int = 0
	private var m_touchIDX: Int = 0
	private var m_needsLayout: Bool = true
	
	private var theSegments: [Segment] = []
	
	private let ringLayer: CAShapeLayer = CAShapeLayer()
	private let linesLayer: CAShapeLayer = CAShapeLayer()
	private let segmentLayer: CAShapeLayer = CAShapeLayer()
	
	// array to hold the labels
	private var arcTexts: [ArcTextView] = []
	
	// The display link for animation
	private var displayLink: CADisplayLink?
	private var startTime: TimeInterval = 0.0
	
	// properties used for animation
	private var sourceDegreeStart: Double = 0.0
	private var sourceDegreeEnd: Double = 0.0
	private var startDegreeDist: Double = 0.0
	
	private var targetDegreeStart: Double = 0.0
	private var targetDegreeEnd: Double = 0.0
	private var endDegreeDist: Double = 0.0
	
	// used to track layout changes
	private var myBounds: CGRect = .zero
	
	init() {
		super.init(frame: .zero)
		commonInit()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	private func commonInit() {
		
		ringLayer.fillColor = ringFillColor.cgColor
		ringLayer.strokeColor = nil
		ringLayer.lineWidth = 1.0
		
		linesLayer.fillColor = nil
		linesLayer.strokeColor = ringStrokeColor.cgColor
		linesLayer.lineWidth = 1.0
		
		segmentLayer.fillColor = segmentColor.cgColor
		segmentLayer.strokeColor = UIColor.clear.cgColor
		
		segmentLayer.shadowColor = UIColor.black.cgColor
		segmentLayer.shadowOffset = .zero
		segmentLayer.shadowRadius = 2.0
		segmentLayer.shadowOpacity = segmentShadowOpacity

		layer.addSublayer(ringLayer)
		layer.addSublayer(linesLayer)
		layer.addSublayer(segmentLayer)
		
		// Setup the display link
		displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
		displayLink?.add(to: .current, forMode: .common)
		
		// Pause the display link initially
		displayLink?.isPaused = true
		
	}
	
	private func setMyNeedsLayout() {
		m_needsLayout = true
		setNeedsLayout()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if myBounds != bounds || m_needsLayout {
			myBounds = bounds
			m_needsLayout = false
			updateLayout()
		}
	}
	
	private func updateLayout() {
		
		let r1: Double = bounds.width * 0.5
		let r2: Double = r1 - ringWidth
		
		let cntr: CGPoint = .init(x: bounds.midX, y: bounds.midY)
		
		// create the "ring background" path
		let p1 = UIBezierPath(ovalIn: bounds)
		let p2 = UIBezierPath(ovalIn: bounds.insetBy(dx: ringWidth, dy: ringWidth))
		p1.append(p2)
		p1.usesEvenOddFillRule = true
		ringLayer.path = p1.cgPath
		ringLayer.fillRule = .evenOdd

		// clear the labels
		for v in arcTexts {
			v.removeFromSuperview()
		}
		arcTexts = []
		
		if titles.isEmpty { return }
		
		theSegments = []
		
		var segWidths: [Double] = []
		var dist: Distribution = distribution
		
		if distribution == .userDefined {
			if segmentWidthsInDegrees.isEmpty {
				dist = .equal
			} else {
				segWidths = segmentWidthsInDegrees
				if segWidths.count < titles.count {
					let totalWidths: Double = segmentWidthsInDegrees.reduce(0, +)
					let remaining: Double = 360.0 - totalWidths
					let n = titles.count - segmentWidthsInDegrees.count
					let diff: Double = remaining / Double(n)
					for _ in 0..<n {
						segWidths.append(diff)
					}
				}
			}
		}
		
		if dist == .equal {
			segWidths = Array(repeating: 360.0 / Double(titles.count), count: titles.count)
		} else if dist == .proportional {
			var strLengths: [Double] = []
			let fontAttributes = [NSAttributedString.Key.font: font]
			for str in titles {
				strLengths.append(str.size(withAttributes: fontAttributes).width)
			}
			let totalLen: Double = strLengths.reduce(0, +)
			for len in strLengths {
				segWidths.append(360.0 * (len / totalLen))
			}
		}

		var d: Double = 0.0
		for (i, t) in titles.enumerated() {
			let seg = Segment()
			seg.title = t
			seg.startAngleInDegrees = d
			d += segWidths[i]
			seg.endAngleInDegrees = d
			theSegments.append(seg)
		}

		if !theSegments.isEmpty {
			// pOuter and pInner paths are used to get the points for the separator lines
			let pOuter = UIBezierPath()
			let pInner = UIBezierPath()
			let pLines = UIBezierPath()
			
			var d1: Double = -1.0
			var d2: Double = -1.0
			for i in 0..<theSegments.count {
				d1 = degreesToRadians(theSegments[i].startAngleInDegrees)
				d2 = degreesToRadians(theSegments[i].endAngleInDegrees)

				d1 += degreesToRadians(originDegrees)
				d2 += degreesToRadians(originDegrees)
				
				pOuter.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pInner.addArc(withCenter: cntr, radius: r2, startAngle: d1, endAngle: d2, clockwise: true)
				
				// add separator line
				pLines.move(to: pOuter.currentPoint)
				pLines.addLine(to: pInner.currentPoint)
				
				// create path used to detect touch
				let pSeg = UIBezierPath()
				pSeg.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pSeg.addArc(withCenter: cntr, radius: r2, startAngle: d2, endAngle: d1, clockwise: false)
				pSeg.close()
				theSegments[i].path = pSeg
				
				// create arc-following text view
				let v = ArcTextView()
				v.translatesAutoresizingMaskIntoConstraints = false
				addSubview(v)
				
				NSLayoutConstraint.activate([
					v.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
					v.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0),
					v.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0.0),
					v.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -0.0),
				])
				
				// configure the arc-text
				v.text = theSegments[i].title
				v.startAngle = degreesToRadians(midAngle(a1: theSegments[i].startAngleInDegrees, a2: theSegments[i].endAngleInDegrees) + originDegrees)
				v.radius = r1 - ringWidth / 2.0
				v.textColor = textColor
				v.font = font
				arcTexts.append(v)
			}
			
			// if segments don't fill the circle, add a separator line at 360.0 degrees
			if let seg = theSegments.last, floor(seg.endAngleInDegrees) < 360.0 {
				d2 = degreesToRadians(360.0 + originDegrees)
				pOuter.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pInner.addArc(withCenter: cntr, radius: r2, startAngle: d1, endAngle: d2, clockwise: true)
				pLines.move(to: pOuter.currentPoint)
				pLines.addLine(to: pInner.currentPoint)
			}
			
			pLines.append(UIBezierPath(ovalIn: bounds))
			pLines.append(UIBezierPath(ovalIn: bounds.insetBy(dx: ringWidth, dy: ringWidth)))
			
			linesLayer.path = pLines.cgPath
			
			updateSegment(m_selectedSegment)
		}
		
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		// don't allow a new selection while animation is in progress
		if let dl = displayLink, !dl.isPaused {
			return
		}
		
		m_touchIDX = -1
		
		guard let t = touches.first else { return }
		let p = t.location(in: self)
		
		for i in 0..<theSegments.count {
			if theSegments[i].path.contains(p) {
				// if the current selected segment was tapped, don't do anything
				if m_selectedSegment == i {
					break
				}
				m_touchIDX = i
				arcTexts[m_touchIDX].alpha = 0.4
				break
			}
		}
	}
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if m_touchIDX < 0 {
			return
		}
		guard let t = touches.first else { return }
		let p = t.location(in: self)
		arcTexts[m_touchIDX].alpha = theSegments[m_touchIDX].path.contains(p) ? 0.4 : 1.0
	}
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if m_touchIDX < 0 {
			return
		}
		guard let t = touches.first else { return }
		let p = t.location(in: self)
		arcTexts[m_touchIDX].alpha = 1.0
		if theSegments[m_touchIDX].path.contains(p) {
			animateSegment(from: m_selectedSegment, to: m_touchIDX)
			m_selectedSegment = m_touchIDX
			self.sendActions(for: .valueChanged)
		}
	}
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		if m_touchIDX < 0 {
			return
		}
		arcTexts[m_touchIDX].alpha = 1.0
	}

	/*
	 Arc with rounded corners - based on https://stackoverflow.com/a/61977919/6257435
	 */
	func drawSegment(startDegree: Double, endDegree: Double) {
		
		let startAngle = degreesToRadians(startDegree + 1.0)
		let endAngle = degreesToRadians(endDegree - 1.0)
		
		let clockwise: Bool = true
		let r1: Double = bounds.width * 0.5 - 3.0
		let r2: Double = (r1 - ringWidth) + 6.0
		
		let center: CGPoint = .init(x: bounds.midX, y: bounds.midY)
		
		let innerRadius = r2
		let innerAngularDelta = asin(cornerRadius / (innerRadius + cornerRadius)) * (clockwise ? 1 : -1)
		let outerRadius = r1
		let outerAngularDelta = asin(cornerRadius / (outerRadius - cornerRadius)) * (clockwise ? 1 : -1)
		
		let path = UIBezierPath(arcCenter: center, radius: innerRadius, startAngle: startAngle + innerAngularDelta, endAngle: endAngle - innerAngularDelta, clockwise: clockwise)
		
		var angle = endAngle - innerAngularDelta
		var cornerStartAngle = angle + .pi * (clockwise ? 1 : -1)
		var cornerEndAngle = endAngle + .pi / 2 * (clockwise ? 1 : -1)
		var cornerCenter = CGPoint(x: center.x + (innerRadius + cornerRadius) * cos(angle), y: center.y + (innerRadius + cornerRadius) * sin(angle))
		path.addArc(withCenter: cornerCenter, radius: cornerRadius, startAngle: cornerStartAngle, endAngle: cornerEndAngle, clockwise: !clockwise)
		
		angle = endAngle - outerAngularDelta
		cornerStartAngle = cornerEndAngle
		cornerEndAngle = endAngle - outerAngularDelta
		cornerCenter = CGPoint(x: center.x + (outerRadius - cornerRadius) * cos(angle), y: center.y + (outerRadius - cornerRadius) * sin(angle))
		path.addArc(withCenter: cornerCenter, radius: cornerRadius, startAngle: cornerStartAngle, endAngle: cornerEndAngle, clockwise: !clockwise)
		
		path.addArc(withCenter: center, radius: outerRadius, startAngle: endAngle - outerAngularDelta, endAngle: startAngle + outerAngularDelta, clockwise: !clockwise)
		
		angle = startAngle + outerAngularDelta
		cornerStartAngle = angle
		cornerEndAngle = startAngle - .pi / 2 * (clockwise ? 1 : -1)
		cornerCenter = CGPoint(x: center.x + (outerRadius - cornerRadius) * cos(angle), y: center.y + (outerRadius - cornerRadius) * sin(angle))
		path.addArc(withCenter: cornerCenter, radius: cornerRadius, startAngle: cornerStartAngle, endAngle: cornerEndAngle, clockwise: !clockwise)
		
		angle = startAngle + innerAngularDelta
		cornerStartAngle = cornerEndAngle
		cornerEndAngle = angle + .pi * (clockwise ? 1 : -1)
		cornerCenter = CGPoint(x: center.x + (innerRadius + cornerRadius) * cos(angle), y: center.y + (innerRadius + cornerRadius) * sin(angle))
		path.addArc(withCenter: cornerCenter, radius: cornerRadius, startAngle: cornerStartAngle, endAngle: cornerEndAngle, clockwise: !clockwise)
		
		path.close()
		
		segmentLayer.path = path.cgPath
		
	}
	
	func animateSegment(from fromSeg: Int, to toSeg: Int) {
		sourceDegreeStart = theSegments[fromSeg].startAngleInDegrees + originDegrees
		sourceDegreeEnd = theSegments[fromSeg].endAngleInDegrees + originDegrees
		targetDegreeStart = theSegments[toSeg].startAngleInDegrees + originDegrees
		targetDegreeEnd = theSegments[toSeg].endAngleInDegrees + originDegrees
		
		let g1 = midAngle(a1: sourceDegreeStart, a2: sourceDegreeEnd)
		let g2 = midAngle(a1: targetDegreeStart, a2: targetDegreeEnd)
		let absD = abs(g2 - g1)
		
		// we want to animate the segment using the shorter distance/direction around the ring
		if absD > 180.0 {
			if g1 < g2 {
				targetDegreeStart -= 360.0
				targetDegreeEnd -= 360.0
			} else {
				targetDegreeStart += 360.0
				targetDegreeEnd += 360.0
			}
		}
		
		startDegreeDist = targetDegreeStart - sourceDegreeStart
		endDegreeDist = targetDegreeEnd - sourceDegreeEnd
		
		startAnimation()
	}
	
	@objc func startAnimation() {
		// Reset start time
		startTime = CACurrentMediaTime()
		// Unpause the display link to start animation
		displayLink?.isPaused = false
	}
	
	@objc func updateAnimation() {
		let currentTime = CACurrentMediaTime()
		let elapsedTime = currentTime - startTime
		
		let t = elapsedTime / animationDuration
		if t >= 1.0 {
			// Animation complete
			displayLink?.isPaused = true
			self.drawSegment(startDegree: theSegments[self.m_selectedSegment].startAngleInDegrees + originDegrees, endDegree: theSegments[self.m_selectedSegment].endAngleInDegrees + originDegrees)
			return
		}
		
		// Apply ease-in-ease-out algorithm
		let easedT = easeInOut(CGFloat(t))
		
		let newSt = self.sourceDegreeStart + self.startDegreeDist * easedT
		let newEnd = self.sourceDegreeEnd + self.endDegreeDist * easedT
		self.drawSegment(startDegree: newSt, endDegree: newEnd)
	}

	func updateSegment(_ n: Int) {
		drawSegment(startDegree: theSegments[n].startAngleInDegrees + originDegrees, endDegree: theSegments[n].endAngleInDegrees + originDegrees)
		m_selectedSegment = n
	}
	
	func easeInOut(_ t: CGFloat) -> CGFloat {
		return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
	}
	
	func radiansToDegrees(_ radians: Double) -> Double {
		return radians / (.pi / 180.0)
	}
	func degreesToRadians(_ degrees: Double) -> Double {
		return degrees * .pi / 180.0
	}
	func midAngle(a1: Double, a2: Double) -> Double {
		return (a1 + a2) * 0.5
	}
		
}

