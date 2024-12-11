//
//  SampleSegmentTitles.h
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleSegmentTitles : NSObject

@property (nonatomic, strong) NSArray<NSString *> *daysOfTheWeek;
@property (nonatomic, strong, readonly) NSArray<NSString *> *uiKitNamedColors;

- (NSArray<NSString *> *)alphabetWithNumChars:(NSInteger)numChars;

@end

NS_ASSUME_NONNULL_END
