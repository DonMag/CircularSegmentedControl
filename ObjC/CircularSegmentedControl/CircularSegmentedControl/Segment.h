//
//  Segment.h
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Segment : NSObject

@property (nonatomic, copy) NSString *title; // Title for the segment
@property (nonatomic, assign) double startAngleInDegrees; // Start angle in degrees
@property (nonatomic, assign) double endAngleInDegrees; // End angle in degrees
@property (nonatomic, strong) UIBezierPath *path; // Path for the segment

// Computed property equivalent for midAngleInDegrees
- (double)midAngleInDegrees;

@end

NS_ASSUME_NONNULL_END
