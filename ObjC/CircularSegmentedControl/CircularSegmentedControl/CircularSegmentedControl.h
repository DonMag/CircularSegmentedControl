//
//  CircularSegmentedControl.h
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, Distribution) {
	DistributionEqual,
	DistributionProportional,
	DistributionUserDefined
};

@interface CircularSegmentedControl : UIControl

@property (nonatomic, assign) Distribution distribution;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *segmentColor;
@property (nonatomic, assign) float segmentShadowOpacity;
@property (nonatomic, strong) UIColor *ringFillColor;
@property (nonatomic, strong) UIColor *ringStrokeColor;
@property (nonatomic, strong) UIColor *separatorLinesColor;
@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSArray<NSNumber *> *segmentWidthsInDegrees;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) double originDegrees;
@property (nonatomic, assign) NSInteger topIndex;
@property (nonatomic, assign) CGFloat ringWidth;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

- (void)setSelectedSegmentIndex:(NSInteger)index animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
