//
//  CircularSegmentedControl.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import "CircularSegmentedControl.h"
#import "Segment.h"
#import "ArcTextView.h"

@interface CircularSegmentedControl ()

@property (nonatomic, assign) NSInteger m_selectedSegment;
@property (nonatomic, assign) double m_originDegrees;
@property (nonatomic, assign) NSInteger m_touchIDX;
@property (nonatomic, assign) BOOL m_needsLayout;
@property (nonatomic, strong) NSMutableArray <Segment *> *theSegments;
@property (nonatomic, strong) CAShapeLayer *ringLayer;
@property (nonatomic, strong) CAShapeLayer *separatorLinesLayer;
@property (nonatomic, strong) CAShapeLayer *segmentLayer;
@property (nonatomic, strong) NSMutableArray *arcTexts;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) double sourceDegreeStart;
@property (nonatomic, assign) double sourceDegreeEnd;
@property (nonatomic, assign) double targetDegreeStart;
@property (nonatomic, assign) double targetDegreeEnd;
@property (nonatomic, assign) double startDegreeDist;
@property (nonatomic, assign) double endDegreeDist;
@property (nonatomic, assign) CGRect myBounds;

@end

@implementation CircularSegmentedControl

- (instancetype)init {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit {
	
	_distribution = DistributionEqual;
	_font = [UIFont systemFontOfSize:16];
	_textColor = [UIColor blackColor];
	_segmentColor = [UIColor whiteColor];
	_segmentShadowOpacity = 0.2;
	_ringFillColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	_ringStrokeColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	_separatorLinesColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	_animationDuration = 0.3;
	_m_originDegrees = 0.0;
	_topIndex = -1;
	_ringWidth = 40.0;
	_cornerRadius = 6.0;
	_selectedSegmentIndex = 0;
	
	_m_selectedSegment = 0;
	_m_touchIDX = 0;
	
	_ringLayer = [CAShapeLayer layer];
	_separatorLinesLayer = [CAShapeLayer layer];
	_segmentLayer = [CAShapeLayer layer];
	_arcTexts = [NSMutableArray array];
	_theSegments = [NSMutableArray array];
	
	_ringLayer.fillColor = _ringFillColor.CGColor;
	_ringLayer.strokeColor = _ringStrokeColor.CGColor;
	
	_separatorLinesLayer.fillColor = NULL;
	_separatorLinesLayer.strokeColor = _separatorLinesColor.CGColor;
	_separatorLinesLayer.lineWidth = 1.0;
	
	_segmentLayer.fillColor = _segmentColor.CGColor;
	_segmentLayer.strokeColor = UIColor.clearColor.CGColor;
	
	_segmentLayer.shadowColor = UIColor.blackColor.CGColor;
	_segmentLayer.shadowOffset = CGSizeZero;
	_segmentLayer.shadowRadius = 2.0;
	_segmentLayer.shadowOpacity = _segmentShadowOpacity;

	[self.layer addSublayer:_ringLayer];
	[self.layer addSublayer:_separatorLinesLayer];
	[self.layer addSublayer:_segmentLayer];
	
	// Setup the display link
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimation)];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	
	// Pause the display link initially
	_displayLink.paused = YES;
	
	[self setMyNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (!CGRectEqualToRect(_myBounds, self.bounds) || _m_needsLayout) {
		_myBounds = self.bounds;
		_m_needsLayout = NO;
		[self updateLayout];
	}
}
- (void)setMyNeedsLayout {
	_m_needsLayout = YES;
	[self setNeedsLayout];
}
- (void)updateLayout {
	double r1 = self.bounds.size.width * 0.5;
	double r2 = r1 - self.ringWidth;
	
	CGPoint cntr = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	
	// create the "ring background" path
	UIBezierPath *p1 = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
	UIBezierPath *p2 = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, self.ringWidth, self.ringWidth)];
	[p1 appendPath:p2];
	p1.usesEvenOddFillRule = YES;
	self.ringLayer.path = p1.CGPath;
	self.ringLayer.fillRule = kCAFillRuleEvenOdd;
	
	// clear the labels
	for (UIView *v in self.arcTexts) {
		[v removeFromSuperview];
	}
	self.arcTexts = [NSMutableArray array];
	
	if (self.titles.count == 0) {
		return;
	}
	
	self.theSegments = [NSMutableArray array];
	NSMutableArray <NSNumber *> *segWidths = [NSMutableArray array];
	Distribution dist = self.distribution;

	if (self.distribution == DistributionUserDefined) {
		if (self.segmentWidthsInDegrees.count == 0) {
			dist = DistributionEqual;
		} else {
			segWidths = [self.segmentWidthsInDegrees mutableCopy];
			// if there are more user-defined widths than titles
			// strip off the extras
			while (segWidths.count > self.titles.count) {
				[segWidths removeLastObject];
			}
			// if there are fewer user-defined widths than titles
			// append Zeroes to the end
			while (segWidths.count < self.titles.count) {
				[segWidths addObject:@(0.0)];
			}
			// replace any Zero-widths with equal widths
			double totalWidths = [[segWidths valueForKeyPath:@"@sum.doubleValue"] doubleValue];
			double remaining = 360.0 - totalWidths;
			NSUInteger nZeroes = [[segWidths filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == 0"]] count];
			if (nZeroes > 0) {
				double diff = remaining / (double)nZeroes;
				for (NSUInteger i = 0; i < segWidths.count; i++) {
					if ([segWidths[i] doubleValue] == 0.0) {
						segWidths[i] = @(diff);
					}
				}
			}
		}
	}
	
	if (dist == DistributionEqual) {
		for (int i = 0; i < self.titles.count; i++) {
			[segWidths addObject:@(360.0 / self.titles.count)];
		}
	} else if (dist == DistributionProportional) {
		NSMutableArray *strLengths = [NSMutableArray array];
		NSDictionary *fontAttributes = @{NSFontAttributeName: self.font};
		double totalLen = 0.0;
		
		for (NSString *str in self.titles) {
			CGSize size = [str sizeWithAttributes:fontAttributes];
			[strLengths addObject:@(size.width)];
			totalLen += size.width;
		}
		
		NSMutableArray *segWidths = [NSMutableArray array];
		for (NSNumber *len in strLengths) {
			double width = 360.0 * ([len doubleValue] / totalLen);
			[segWidths addObject:@(width)];
		}
	}

	double d = 0.0;
	for (NSUInteger i = 0; i <self.titles.count; i++) {
		Segment *seg = [Segment new];
		seg.title = self.titles[i];
		seg.startAngleInDegrees = d;
		d += [segWidths[i] doubleValue];
		seg.endAngleInDegrees = d;
		[self.theSegments addObject:seg];
	}

	if (_topIndex >= 0) {
		Segment *topSeg = self.theSegments[self.topIndex];
		double segW = topSeg.endAngleInDegrees - topSeg.startAngleInDegrees;
		self.m_originDegrees = -topSeg.startAngleInDegrees;
		self.m_originDegrees -= 90.0;
		self.m_originDegrees -= segW * 0.5;
	} else {
		self.m_originDegrees = self.originDegrees;
	}

	if (self.theSegments.count > 0) {
		// pOuter and pInner paths are used to get the points for the separator lines
		UIBezierPath *pOuter = [UIBezierPath bezierPath];
		UIBezierPath *pInner = [UIBezierPath bezierPath];
		UIBezierPath *pLines = [UIBezierPath bezierPath];
		
		double d1 = -1.0;
		double d2 = -1.0;
		
		for (int i = 0; i < self.theSegments.count; i++) {
			Segment *segment = self.theSegments[i];
			d1 = [self degreesToRadians:segment.startAngleInDegrees];
			d2 = [self degreesToRadians:segment.endAngleInDegrees];
			
			d1 += [self degreesToRadians:self.m_originDegrees];
			d2 += [self degreesToRadians:self.m_originDegrees];
			
			[pOuter addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pInner addArcWithCenter:cntr radius:r2 startAngle:d1 endAngle:d2 clockwise:YES];
			
			// add separator line
			[pLines moveToPoint:pOuter.currentPoint];
			[pLines addLineToPoint:pInner.currentPoint];
			
			// create path used to detect touch
			UIBezierPath *pSeg = [UIBezierPath bezierPath];
			[pSeg addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pSeg addArcWithCenter:cntr radius:r2 startAngle:d2 endAngle:d1 clockwise:NO];
			[pSeg closePath];
			segment.path = pSeg;
			
			// create arc-following text view
			ArcTextView *v = [[ArcTextView alloc] init];
			v.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:v];
			
			[NSLayoutConstraint activateConstraints:@[
				[v.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0],
				[v.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0],
				[v.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0],
				[v.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0]
			]];
			
			// configure the arc-text
			v.text = segment.title;
			v.startAngle = [self degreesToRadians:[self midAngle:segment.startAngleInDegrees a2:segment.endAngleInDegrees] + self.m_originDegrees];
			v.radius = r1 - self.ringWidth / 2.0;
			v.textColor = self.textColor;
			v.font = self.font;
			
			// the arc-text may be too big to fit
			//	so we create a path matching the "arc segment"
			//	inset a little bit
			//	to use as a mask
			d1 += [self degreesToRadians:2.0];
			d2 -= [self degreesToRadians:2.0];
			pSeg = [UIBezierPath bezierPath];
			[pSeg addArcWithCenter:cntr radius:r1 - 4.0 startAngle:d1 endAngle:d2 clockwise:YES];
			[pSeg addArcWithCenter:cntr radius:r2 + 4.0 startAngle:d2 endAngle:d1 clockwise:NO];
			[pSeg closePath];

			CAShapeLayer *msk = [CAShapeLayer new];
			msk.fillColor = UIColor.redColor.CGColor;
			msk.strokeColor = UIColor.clearColor.CGColor;
			msk.path = pSeg.CGPath;
			v.layer.mask = msk;
			
			[self.arcTexts addObject:v];
		}

		// if explicit segment widths are used, and
		//	segments don't fill the circle, add a separator line at 360.0 degrees
		if (self.theSegments.lastObject && floor(self.theSegments.lastObject.endAngleInDegrees) < 360.0) {
			d2 = [self degreesToRadians:360.0 + self.m_originDegrees];
			[pOuter addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pInner addArcWithCenter:cntr radius:r2 startAngle:d1 endAngle:d2 clockwise:YES];
			[pLines moveToPoint:pOuter.currentPoint];
			[pLines addLineToPoint:pInner.currentPoint];
		}
		
		self.separatorLinesLayer.path = pLines.CGPath;
		
		[self updateSegment:self.m_selectedSegment];
	}
}

/*
 Arc with rounded corners - based on https://stackoverflow.com/a/61977919/6257435
 */
- (void)drawSegmentWithStartDegree:(double)startDegree endDegree:(double)endDegree {

	double startAngle = [self degreesToRadians:startDegree + 1.0];
	double endAngle = [self degreesToRadians:endDegree - 1.0];
	
	BOOL clockwise = YES;
	double r1 = self.bounds.size.width * 0.5 - 3.0;
	double r2 = (r1 - self.ringWidth) + 6.0;
	
	CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	
	double innerRadius = r2;
	double innerAngularDelta = asin(self.cornerRadius / (innerRadius + self.cornerRadius)) * (clockwise ? 1 : -1);
	double outerRadius = r1;
	double outerAngularDelta = asin(self.cornerRadius / (outerRadius - self.cornerRadius)) * (clockwise ? 1 : -1);
	
	UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center
														radius:innerRadius
													startAngle:startAngle + innerAngularDelta
													  endAngle:endAngle - innerAngularDelta
													 clockwise:clockwise];
	
	double angle = endAngle - innerAngularDelta;
	double cornerStartAngle = angle + M_PI * (clockwise ? 1 : -1);
	double cornerEndAngle = endAngle + M_PI_2 * (clockwise ? 1 : -1);
	CGPoint cornerCenter = CGPointMake(center.x + (innerRadius + self.cornerRadius) * cos(angle),
									   center.y + (innerRadius + self.cornerRadius) * sin(angle));
	[path addArcWithCenter:cornerCenter
					radius:self.cornerRadius
				startAngle:cornerStartAngle
				  endAngle:cornerEndAngle
				 clockwise:!clockwise];
	
	angle = endAngle - outerAngularDelta;
	cornerStartAngle = cornerEndAngle;
	cornerEndAngle = endAngle - outerAngularDelta;
	cornerCenter = CGPointMake(center.x + (outerRadius - self.cornerRadius) * cos(angle),
							   center.y + (outerRadius - self.cornerRadius) * sin(angle));
	[path addArcWithCenter:cornerCenter
					radius:self.cornerRadius
				startAngle:cornerStartAngle
				  endAngle:cornerEndAngle
				 clockwise:!clockwise];
	
	[path addArcWithCenter:center
					radius:outerRadius
				startAngle:endAngle - outerAngularDelta
				  endAngle:startAngle + outerAngularDelta
				 clockwise:!clockwise];
	
	angle = startAngle + outerAngularDelta;
	cornerStartAngle = angle;
	cornerEndAngle = startAngle - M_PI_2 * (clockwise ? 1 : -1);
	cornerCenter = CGPointMake(center.x + (outerRadius - self.cornerRadius) * cos(angle),
							   center.y + (outerRadius - self.cornerRadius) * sin(angle));
	[path addArcWithCenter:cornerCenter
					radius:self.cornerRadius
				startAngle:cornerStartAngle
				  endAngle:cornerEndAngle
				 clockwise:!clockwise];
	
	angle = startAngle + innerAngularDelta;
	cornerStartAngle = cornerEndAngle;
	cornerEndAngle = angle + M_PI * (clockwise ? 1 : -1);
	cornerCenter = CGPointMake(center.x + (innerRadius + self.cornerRadius) * cos(angle),
							   center.y + (innerRadius + self.cornerRadius) * sin(angle));
	[path addArcWithCenter:cornerCenter
					radius:self.cornerRadius
				startAngle:cornerStartAngle
				  endAngle:cornerEndAngle
				 clockwise:!clockwise];
	
	[path closePath];
	
	self.segmentLayer.path = path.CGPath;
	
}

- (void)animateSegmentFrom:(NSInteger)fromSeg to:(NSInteger)toSeg {
	self.sourceDegreeStart = self.theSegments[fromSeg].startAngleInDegrees + self.m_originDegrees;
	self.sourceDegreeEnd = self.theSegments[fromSeg].endAngleInDegrees + self.m_originDegrees;
	self.targetDegreeStart = self.theSegments[toSeg].startAngleInDegrees + self.m_originDegrees;
	self.targetDegreeEnd = self.theSegments[toSeg].endAngleInDegrees + self.m_originDegrees;
	
	double g1 = [self midAngle:self.sourceDegreeStart a2:self.sourceDegreeEnd];
	double g2 = [self midAngle:self.targetDegreeStart a2:self.targetDegreeEnd];
	double absD = fabs(g2 - g1);
	
	// we want to animate the segment using the shorter distance/direction around the ring
	if (absD > 180.0) {
		if (g1 < g2) {
			self.targetDegreeStart -= 360.0;
			self.targetDegreeEnd -= 360.0;
		} else {
			self.targetDegreeStart += 360.0;
			self.targetDegreeEnd += 360.0;
		}
	}
	
	self.startDegreeDist = self.targetDegreeStart - self.sourceDegreeStart;
	self.endDegreeDist = self.targetDegreeEnd - self.sourceDegreeEnd;
	
	[self startAnimation];
}

- (void)startAnimation {
	// Reset start time
	self.startTime = CACurrentMediaTime();
	// Unpause the display link to start animation
	self.displayLink.paused = NO;
}

- (void)updateAnimation {
	CFTimeInterval currentTime = CACurrentMediaTime();
	CFTimeInterval elapsedTime = currentTime - self.startTime;
	
	double t = elapsedTime / self.animationDuration;
	if (t >= 1.0) {
		// Animation complete
		self.displayLink.paused = YES;
		[self drawSegmentWithStartDegree:self.theSegments[self.m_selectedSegment].startAngleInDegrees + self.m_originDegrees
							   endDegree:self.theSegments[self.m_selectedSegment].endAngleInDegrees + self.m_originDegrees];
		return;
	}
	
	// Apply ease-in-ease-out algorithm
	CGFloat easedT = [self easeInOut:(CGFloat)t];
	
	double newSt = self.sourceDegreeStart + self.startDegreeDist * easedT;
	double newEnd = self.sourceDegreeEnd + self.endDegreeDist * easedT;
	[self drawSegmentWithStartDegree:newSt endDegree:newEnd];
}

- (void)updateSegment:(NSInteger)index {
	[self drawSegmentWithStartDegree:_theSegments[index].startAngleInDegrees + self.m_originDegrees endDegree:_theSegments[index].endAngleInDegrees + self.m_originDegrees];
	self.m_selectedSegment = index;
}

- (CGFloat)easeInOut:(CGFloat)t {
	return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

- (double)radiansToDegrees:(double)radians {
	return radians / (M_PI / 180.0);
}
- (double)degreesToRadians:(double)degrees {
	return degrees * M_PI / 180.0;
}
- (double)midAngle:(double)a1 a2:(double)a2 {
	return (a1 + a2) * 0.5;
}

- (void)setSelectedSegmentIndex:(NSInteger)index {
	[self setSelectedSegmentIndex:index animated:NO];
}
- (void)setSelectedSegmentIndex:(NSInteger)index animated:(BOOL)animated {
	if (index < 0 || index > self.titles.count - 1) {
		// out of range, ignore
		return;
	}
	if (!self.m_needsLayout) {
		if (animated && self.m_selectedSegment > -1) {
			[self animateSegmentFrom:self.m_selectedSegment to:index];
		} else {
			[self updateSegment:index];
		}
	}
	self.m_selectedSegment = index;
}

- (void)setTitles:(NSArray<NSString *> *)titles {
	_titles = titles;
	[self setMyNeedsLayout];
}

// Segment widths property
- (void)setSegmentWidthsInDegrees:(NSArray<NSNumber *> *)segmentWidthsInDegrees {
	_segmentWidthsInDegrees = segmentWidthsInDegrees;
	self.distribution = DistributionUserDefined;
	[self setMyNeedsLayout];
}

// Font property
- (void)setFont:(UIFont *)font {
	_font = font;
	if (self.distribution == DistributionProportional) {
		[self setMyNeedsLayout];
	} else {
		for (UILabel *v in self.arcTexts) {
			v.font = font;
		}
	}
}

// Text color property
- (void)setTextColor:(UIColor *)textColor {
	_textColor = textColor;
	for (UILabel *v in self.arcTexts) {
		v.textColor = textColor;
	}
}

// Segment color property
- (void)setSegmentColor:(UIColor *)segmentColor {
	_segmentColor = segmentColor;
	self.segmentLayer.fillColor = segmentColor.CGColor;
}

// Segment shadow property
- (void)setSegmentShadowOpacity:(float)segmentShadowOpacity {
	_segmentShadowOpacity = segmentShadowOpacity;
	self.segmentLayer.shadowOpacity = segmentShadowOpacity;
}

// Ring fill color property
- (void)setRingFillColor:(UIColor *)ringFillColor {
	_ringFillColor = ringFillColor;
	self.ringLayer.fillColor = ringFillColor.CGColor;
}

// Ring stroke color property
- (void)setRingStrokeColor:(UIColor *)ringStrokeColor {
	_ringStrokeColor = ringStrokeColor;
	self.ringLayer.strokeColor = ringStrokeColor.CGColor;
}

// Separator lines color property
- (void)setSeparatorLinesColor:(UIColor *)separatorLinesColor {
	_separatorLinesColor = separatorLinesColor;
	self.separatorLinesLayer.strokeColor = separatorLinesColor.CGColor;
}

// angle for start of first segment
- (void)setOriginDegrees:(double)originDegrees {
	_originDegrees = originDegrees;
	[self setMyNeedsLayout];
}

// index of segment to center at top
- (void)setTopIndex:(NSInteger)topIndex {
	_topIndex = topIndex;
	[self setMyNeedsLayout];
}

// width of ring
- (void)setRingWidth:(CGFloat)ringWidth {
	_ringWidth = ringWidth;
	[self setMyNeedsLayout];
}

// radius of segment corners
- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	[self setMyNeedsLayout];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	
	// don't allow a new selection while animation is in progress
	if (self.displayLink && !self.displayLink.isPaused) {
		return;
	}
	
	self.m_touchIDX = -1;
	
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	
	for (NSInteger i = 0; i < self.theSegments.count; i++) {
		Segment *segment = self.theSegments[i];
		if ([segment.path containsPoint:p]) {
			// if the current selected segment was tapped, don't do anything
			if (self.m_selectedSegment == i) {
				break;
			}
			self.m_touchIDX = i;
			((UIView *)self.arcTexts[self.m_touchIDX]).alpha = 0.4;
			break;
		}
	}
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	
	if (self.m_touchIDX < 0) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	Segment *segment = self.theSegments[self.m_touchIDX];
	((UIView *)self.arcTexts[self.m_touchIDX]).alpha = [segment.path containsPoint:p] ? 0.4 : 1.0;
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	
	if (self.m_touchIDX < 0) {
		return;
	}
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	((UIView *)self.arcTexts[self.m_touchIDX]).alpha = 1.0;
	Segment *segment = self.theSegments[self.m_touchIDX];
	if ([segment.path containsPoint:p]) {
		[self animateSegmentFrom:self.m_selectedSegment to:self.m_touchIDX];
		self.m_selectedSegment = self.m_touchIDX;
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesCancelled:touches withEvent:event];
	
	if (self.m_touchIDX < 0) {
		return;
	}
	((UIView *)self.arcTexts[self.m_touchIDX]).alpha = 1.0;
}

@end

