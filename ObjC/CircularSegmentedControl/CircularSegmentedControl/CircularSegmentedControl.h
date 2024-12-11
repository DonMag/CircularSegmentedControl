//
//  CircularSegmentedControl.h
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CircularSegmentedControl : UIControl

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *segmentColor;
@property (nonatomic, assign) float segmentShadowOpacity;
@property (nonatomic, strong) UIColor *ringFillColor;
@property (nonatomic, strong) UIColor *ringStrokeColor;
@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSArray<NSNumber *> *segmentWidthsInDegrees;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) double originDegrees;
@property (nonatomic, assign) CGFloat ringWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

@end

NS_ASSUME_NONNULL_END
