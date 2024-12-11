//
//  ArcTextView.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

import UIKit

class ArcTextView: UIView {
	var text: String = "Text Along Arc"
	var startAngle: CGFloat = 0.0
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
			// Rotate to align with the arc
			context.rotate(by: charAngle + .pi / 2)
			
			// Draw the character
			charString.draw(at: CGPoint(x: -charSize.width / 2, y: -charSize.height / 2), withAttributes: attributes)
			
			// Restore the context's state
			context.restoreGState()
			
			// Update the current angle
			currentAngle += charSize.width / radius
		}
	}
}
