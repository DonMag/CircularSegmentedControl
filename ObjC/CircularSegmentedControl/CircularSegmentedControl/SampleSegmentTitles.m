//
//  SampleSegmentTitles.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

#import "SampleSegmentTitles.h"

@implementation SampleSegmentTitles

- (instancetype)init {
	self = [super init];
	if (self) {
		// Initialize daysOfTheWeek
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.locale = [NSLocale currentLocale]; // Use the user's current locale
		formatter.calendar = [NSCalendar currentCalendar]; // Use the user's current calendar
		_daysOfTheWeek = [formatter weekdaySymbols];
		
		// Initialize uiKitNamedColors
		_uiKitNamedColors = @[@"red", @"green", @"blue", @"cyan", @"magenta", @"yellow"];
	}
	return self;
}

- (NSArray<NSString *> *)alphabetWithNumChars:(NSInteger)numChars {
	NSMutableArray<NSString *> *alphabetArray = [NSMutableArray array];
	for (NSInteger i = 65; i < (65 + numChars); i++) {
		NSString *charString = [NSString stringWithFormat:@"%C", (unichar)i];
		[alphabetArray addObject:charString];
	}
	return [alphabetArray copy];
}

@end
