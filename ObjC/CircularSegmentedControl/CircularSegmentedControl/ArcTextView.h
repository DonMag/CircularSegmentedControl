//
//  ArcTextView.h
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcTextView : UIView

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
