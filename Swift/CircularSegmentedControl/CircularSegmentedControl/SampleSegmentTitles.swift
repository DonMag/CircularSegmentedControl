//
//  SampleSegmentTitles.swift
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

import UIKit

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
