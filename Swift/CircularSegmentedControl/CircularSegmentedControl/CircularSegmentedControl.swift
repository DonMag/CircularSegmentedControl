//
//  CircularSegmentedControl.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/6/24.
//

import UIKit

class CircularSegmentedControl: UIControl {

	public var font: UIFont = .systemFont(ofSize: 16) {
		didSet {
			for v in arcTexts {
				v.font = font
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
	public var titles: [String] = [] {
		didSet {
			theSegments = []
			let segSize = 360.0 / Double(titles.count)
			var d: Double = 0.0
			for (i, t) in titles.enumerated() {
				var seg = MySegment()
				seg.title = t
				seg.startAngleInDegrees = d
				if !segmentWidthsInDegrees.isEmpty {
					if i == titles.count - 1, segmentWidthsInDegrees.count < titles.count {
						d = 360.0
					} else {
						d += segmentWidthsInDegrees[i]
					}
				} else {
					d += segSize
				}
				seg.endAngleInDegrees = d
				theSegments.append(seg)
			}
			updateLayout()
		}
	}
	public var segmentWidthsInDegrees: [Double] = [] {
		didSet {
			if !theSegments.isEmpty {
				guard segmentWidthsInDegrees.count >= theSegments.count - 1 else {
					//fatalError("Must set segment widths to 1 less than titles count")
					return
				}
				var d: Double = 0.0
				for i in 0..<theSegments.count {
					theSegments[i].startAngleInDegrees = d
					if i == theSegments.count - 1, segmentWidthsInDegrees.count < theSegments.count {
						theSegments[i].endAngleInDegrees = 360.0
					} else {
						d += segmentWidthsInDegrees[i]
						theSegments[i].endAngleInDegrees = d
					}
				}
				updateLayout()
			}
		}
	}
	
	// Duration of segment animation in seconds
	public var animationDuration: TimeInterval = 0.3
	
	public var originDegrees: Double = 0.0 { didSet { updateLayout() } }
	
	public var ringWidth: CGFloat = 40.0 { didSet { updateLayout() } }
	
	public var cornerRadius: CGFloat = 6.0 { didSet { updateLayout() } }
	
	public var selectedSegmentIndex: Int {
		set {
			updateSegment(newValue)
		}
		get {
			return _selectedSegment
		}
	}
	public func setSelectedSegmentIndex(_ n: Int, animated: Bool) {
		if animated, _selectedSegment > -1 {
			animateSegment(from: _selectedSegment, to: n)
		} else {
			updateSegment(n)
		}
		_selectedSegment = n
	}
	
	private var _selectedSegment: Int = -1
	
	private struct MySegment {
		var title: String = "A"
		var startAngleInDegrees: Double = 0.0
		var endAngleInDegrees: Double = 0.0
		var midAngleInDegrees: Double {
			return (startAngleInDegrees + endAngleInDegrees) * 0.5
		}
		var path: UIBezierPath = UIBezierPath()
	}
	
	private var theSegments: [MySegment] = []
	
	private let ringLayer: CAShapeLayer = CAShapeLayer()
	private let linesLayer: CAShapeLayer = CAShapeLayer()
	private let segmentLayer: CAShapeLayer = CAShapeLayer()
	
	// array to hold the labels
	private var arcTexts: [ArcTextView] = []

	// The display link for animation
	private var displayLink: CADisplayLink?
	private var startTime: TimeInterval = 0.0

	// properties used for animation
	private var sourceDegreeStart = 0.0
	private var sourceDegreeEnd = 0.0
	private var startDegreeDist: CGFloat = 0.0
	
	private var targetDegreeStart = 0.0
	private var targetDegreeEnd = 0.0
	private var endDegreeDist: CGFloat = 0.0
	
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
	
	// Setup view
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
		segmentLayer.shadowOpacity = 0.20
		segmentLayer.shadowOffset = .zero
		segmentLayer.shadowRadius = 2.0
		
		layer.addSublayer(ringLayer)
		layer.addSublayer(linesLayer)
		layer.addSublayer(segmentLayer)
		
		// Setup the display link
		displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
		displayLink?.add(to: .current, forMode: .common)
		
		// Pause the display link initially
		displayLink?.isPaused = true
		
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if myBounds != bounds {
			myBounds = bounds
			updateLayout()
		}
	}
	
	private func updateLayout() {
		
		let r1: Double = bounds.width * 0.5
		let r2: Double = r1 - ringWidth
		
		let cntr: CGPoint = .init(x: bounds.midX, y: bounds.midY)
		
		let p1 = UIBezierPath(ovalIn: bounds)
		let p2 = UIBezierPath(ovalIn: bounds.insetBy(dx: ringWidth, dy: ringWidth))
		p1.append(p2)
		p1.usesEvenOddFillRule = true
		ringLayer.path = p1.cgPath
		ringLayer.fillRule = .evenOdd

		for v in arcTexts {
			v.removeFromSuperview()
		}
		arcTexts = []
		
		if !theSegments.isEmpty {
			let pOuter = UIBezierPath()
			let pInner = UIBezierPath()
			let pLines = UIBezierPath()
			
			var d1: Double = -1.0
			var d2: Double = -1.0
			for i in 0..<theSegments.count {
				d1 = theSegments[i].startAngleInDegrees.doubleToRadians()
				d2 = theSegments[i].endAngleInDegrees.doubleToRadians()
				
				pOuter.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pInner.addArc(withCenter: cntr, radius: r2, startAngle: d1, endAngle: d2, clockwise: true)
				
				pLines.move(to: pOuter.currentPoint)
				pLines.addLine(to: pInner.currentPoint)
				
				d1 += originDegrees.doubleToRadians()
				d2 += originDegrees.doubleToRadians()
				
				let pSeg = UIBezierPath()
				pSeg.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pSeg.addArc(withCenter: cntr, radius: r2, startAngle: d2, endAngle: d1, clockwise: false)
				pSeg.close()
				theSegments[i].path = pSeg
				
				let v = ArcTextView()
				v.translatesAutoresizingMaskIntoConstraints = false
				addSubview(v)
				
				NSLayoutConstraint.activate([
					v.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
					v.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0.0),
					v.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0.0),
					v.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -0.0),
				])
				
				v.text = theSegments[i].title
				v.startAngle = ((theSegments[i].midAngleInDegrees) + originDegrees).doubleToRadians()
				v.radius = r1 - ringWidth / 2.0
				v.textColor = textColor
				v.font = font
				arcTexts.append(v)

			}
			
			// if segments don't fill the circle, add a separator line at 360.0 degrees
			if let seg = theSegments.last, floor(seg.endAngleInDegrees) < 360.0 {
				print("add last line")
				d2 = (360.0).doubleToRadians()
				pOuter.addArc(withCenter: cntr, radius: r1, startAngle: d1, endAngle: d2, clockwise: true)
				pInner.addArc(withCenter: cntr, radius: r2, startAngle: d1, endAngle: d2, clockwise: true)
				pLines.move(to: pOuter.currentPoint)
				pLines.addLine(to: pInner.currentPoint)
			}
			
			pLines.append(UIBezierPath(ovalIn: bounds))
			pLines.append(UIBezierPath(ovalIn: bounds.insetBy(dx: ringWidth, dy: ringWidth)))
			
			linesLayer.path = pLines.cgPath
			
			linesLayer.frame = bounds
			segmentLayer.frame = bounds
			
			linesLayer.transform = CATransform3DMakeRotation(originDegrees.doubleToRadians(), 0, 0, 1)
			segmentLayer.transform = CATransform3DMakeRotation(originDegrees.doubleToRadians(), 0, 0, 1)
			
			updateSegment(0)
		}
		
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let dl = displayLink, !dl.isPaused {
			return
		}
		guard let t = touches.first else { return }
		let p = t.location(in: self)
		
		for i in 0..<theSegments.count {
			if theSegments[i].path.contains(p) {
				animateSegment(from: _selectedSegment, to: i)
				_selectedSegment = i
				self.sendActions(for: .valueChanged)
				break
			}
		}
	}
	
	func animateSegment(from fromSeg: Int, to toSeg: Int) {
		sourceDegreeStart = theSegments[fromSeg].startAngleInDegrees
		sourceDegreeEnd = theSegments[fromSeg].endAngleInDegrees
		targetDegreeStart = theSegments[toSeg].startAngleInDegrees
		targetDegreeEnd = theSegments[toSeg].endAngleInDegrees
		
		let g1 = theSegments[fromSeg].midAngleInDegrees
		let g2 = theSegments[toSeg].midAngleInDegrees
		let absD = abs(g2 - g1)
		
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
			self.drawSegment(startDegree: theSegments[self._selectedSegment].startAngleInDegrees, endDegree: theSegments[self._selectedSegment].endAngleInDegrees)
			return
		}
		
		// Apply ease-in-ease-out algorithm
		let easedT = easeInOut(CGFloat(t))
		
		let newSt = self.sourceDegreeStart + self.startDegreeDist * easedT
		let newEnd = self.sourceDegreeEnd + self.endDegreeDist * easedT
		self.drawSegment(startDegree: newSt, endDegree: newEnd)
	}
	func easeInOut(_ t: CGFloat) -> CGFloat {
		return t < 0.5
		? 2 * t * t
		: -1 + (4 - 2 * t) * t
	}
	
	func updateSegment(_ n: Int) {
		drawSegment(startDegree: theSegments[n].startAngleInDegrees, endDegree: theSegments[n].endAngleInDegrees)
		_selectedSegment = n
	}
	
	/*
		Arc with rounded corners - based on https://stackoverflow.com/a/61977919/6257435
	 */
	func drawSegment(startDegree: Double, endDegree: Double) {
		
		let startAngle = (startDegree + 1.0).doubleToRadians()
		let endAngle = (endDegree - 1.0).doubleToRadians()
		
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

	class ArcTextView: UIView {
		var text: String = "Text Along Arc"
		var startAngle: CGFloat = -CGFloat.pi / 2 // Top of the circle
		var radius: CGFloat = 100.0 { didSet { setNeedsDisplay() } }

		var font: UIFont = .systemFont(ofSize: 16) { didSet { setNeedsDisplay() } }
		var textColor: UIColor = .black { didSet { setNeedsDisplay() } }

		override init(frame: CGRect) {
			super.init(frame: frame)
			commonInit()
		}
		required init?(coder: NSCoder) {
			super.init(coder: coder)
			commonInit()
		}
		private func commonInit() {
			backgroundColor = .clear
		}
		override func draw(_ rect: CGRect) {
			super.draw(rect)
			
			guard let context = UIGraphicsGetCurrentContext() else { return }

			// Center of the arc
			let center = CGPoint(x: rect.midX, y: rect.midY)
			
			// Attributes for the text
			let attributes: [NSAttributedString.Key: Any] = [
				.font: font,
				.foregroundColor: textColor,
			]
			// Total arc angle needed to draw the text
			var totalArcLength: CGFloat = 0
			for char in text {
				let charSize = (String(char) as NSString).size(withAttributes: attributes)
				totalArcLength += charSize.width
			}
			
			let totalArcAngle = totalArcLength / radius
			
			// Adjust starting angle to center the text if necessary
			var currentAngle = startAngle - totalArcAngle / 2
			
			// Draw each character
			for char in text {
				let charString = String(char)
				let charSize = (charString as NSString).size(withAttributes: attributes)
				
				// Calculate the position for the character along the arc
				let halfCharAngle = (charSize.width / radius) / 2
				let charAngle = currentAngle + halfCharAngle
				
				// Calculate the character's position
				let x = center.x + radius * cos(charAngle)
				let y = center.y + radius * sin(charAngle)
				
				// Save the context's state
				context.saveGState()
				
				// Move to the character's position and rotate the context
				context.translateBy(x: x, y: y)
				context.rotate(by: charAngle + .pi / 2) // Rotate to align with the arc
				
				// Draw the character
				charString.draw(at: CGPoint(x: -charSize.width / 2, y: -charSize.height / 2), withAttributes: attributes)
				
				// Restore the context's state
				context.restoreGState()
				
				// Update the current angle
				currentAngle += charSize.width / radius
			}
		}
	}

}

extension CGFloat {
	func floatToRadians() -> CGFloat {
		return self * CGFloat(Double.pi) / 180.0
	}
	func floatToDegrees() -> CGFloat {
		return self / (CGFloat(Double.pi) / 180.0)
	}
}
extension Double {
	func doubleToRadians() -> Double {
		return self * .pi / 180.0
	}
	func doubleToDegrees() -> Double {
		return self / (.pi / 180.0)
	}
}
