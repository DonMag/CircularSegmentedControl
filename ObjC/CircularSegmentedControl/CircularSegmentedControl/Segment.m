//
//  Segment.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import "Segment.h"

@implementation Segment

- (instancetype)init {
	self = [super init];
	if (self) {
		_title = @"A";
		_startAngleInDegrees = 0.0;
		_endAngleInDegrees = 0.0;
		_path = [[UIBezierPath alloc] init];
	}
	return self;
}

- (double)midAngleInDegrees {
	return (self.startAngleInDegrees + self.endAngleInDegrees) * 0.5;
}

@end
