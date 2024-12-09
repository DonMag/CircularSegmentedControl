//
//  ViewController.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import "ViewController.h"
#import "CircularSegmentedControl.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	CircularSegmentedControl *csc = [CircularSegmentedControl new];
	csc.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:csc];
	
	UILayoutGuide *g = self.view.safeAreaLayoutGuide;
	
	[NSLayoutConstraint activateConstraints:@[
		[csc.topAnchor constraintEqualToAnchor:g.topAnchor constant:40.0],
		[csc.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:40.0],
		[csc.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-40.0],
		[csc.heightAnchor constraintEqualToAnchor:csc.widthAnchor],
	]];
	
	csc.titles = @[@"A", @"B", @"C", @"D", @"E"];

}


@end
