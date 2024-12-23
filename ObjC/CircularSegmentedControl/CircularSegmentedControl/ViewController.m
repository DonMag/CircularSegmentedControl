//
//  ViewController.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import "ViewController.h"
#import "CircularSegmentedControl.h"
#import "SampleSegmentTitles.h"

@interface ViewController ()
{
	CircularSegmentedControl *csc;
	NSInteger topIDX;
}
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	topIDX = -1;
	
	csc = [CircularSegmentedControl new];
	csc.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:csc];
	
	UILayoutGuide *g = self.view.safeAreaLayoutGuide;
	
	[NSLayoutConstraint activateConstraints:@[
		[csc.topAnchor constraintEqualToAnchor:g.topAnchor constant:40.0],
		[csc.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:40.0],
		[csc.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-40.0],
		[csc.heightAnchor constraintEqualToAnchor:csc.widthAnchor],
	]];
	
	//csc.titles = @[@"A", @"B", @"C", @"D", @"E", @"F"];
	//csc.titles = [[SampleSegmentTitles new] daysOfTheWeek];
	csc.titles = [[SampleSegmentTitles new] alphabetWithNumChars:7];
	csc.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightLight];
	csc.textColor = UIColor.redColor;
	//csc.segmentWidthsInDegrees = @[@80.0, @30.0, @45.0, @60.0, @30.0];
	//csc.segmentWidthsInDegrees = @[@80.0, @30.0, @45.0, @60.0, @30.0, @20.0];
	
	csc.segmentWidthsInDegrees = @[@0.0, @0.0, @0.0, @120.0, @0.0];
	
//	csc.ringStrokeColor = UIColor.clearColor;
//	csc.separatorLinesColor = UIColor.clearColor;
	
	csc.originDegrees = -45.0;
	
	[csc setSelectedSegmentIndex:2 animated:YES];
	
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	
	[csc setSelectedSegmentIndex:7 animated:YES];
	return;
	
	topIDX += 1;
	if (topIDX >= csc.titles.count) {
		topIDX = -1;
	}
	NSLog(@"set top %d", topIDX);
	csc.topIndex = topIDX;
	return;
	
	csc.textColor = UIColor.blueColor;
	csc.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
	csc.ringWidth = 60.0;
}

@end
