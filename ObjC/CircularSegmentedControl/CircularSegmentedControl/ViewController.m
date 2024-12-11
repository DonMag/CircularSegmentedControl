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
}
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

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
	csc.titles = [[SampleSegmentTitles new] daysOfTheWeek];
	csc.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightLight];
	csc.textColor = UIColor.redColor;
	csc.segmentWidthsInDegrees = @[@80.0, @30.0, @45.0, @60.0, @30.0];
	
	csc.originDegrees = -45.0;
	
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	NSLog(@"set 1");
	csc.textColor = UIColor.blueColor;
	csc.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
	csc.ringWidth = 60.0;
}

@end
