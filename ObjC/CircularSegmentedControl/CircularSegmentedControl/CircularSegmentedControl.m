//
//  CircularSegmentedControl.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/9/24.
//

#import "CircularSegmentedControl.h"
#import "Segment.h"

@interface CircularSegmentedControl ()

@property (nonatomic, assign) NSInteger m_selectedSegment;
@property (nonatomic, strong) NSMutableArray <Segment *> *theSegments;
@property (nonatomic, strong) CAShapeLayer *ringLayer;
@property (nonatomic, strong) CAShapeLayer *linesLayer;
@property (nonatomic, strong) CAShapeLayer *segmentLayer;
@property (nonatomic, strong) NSMutableArray *arcTexts;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) double sourceDegreeStart;
@property (nonatomic, assign) double sourceDegreeEnd;
@property (nonatomic, assign) double targetDegreeStart;
@property (nonatomic, assign) double targetDegreeEnd;
@property (nonatomic, assign) CGFloat startDegreeDist;
@property (nonatomic, assign) CGFloat endDegreeDist;
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
	_font = [UIFont systemFontOfSize:16];
	_textColor = [UIColor blackColor];
	_segmentColor = [UIColor whiteColor];
	_ringFillColor = [UIColor colorWithWhite:0.95 alpha:1.0];
	_ringStrokeColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	_animationDuration = 0.3;
	_originDegrees = 0.0;
	_ringWidth = 40.0;
	_cornerRadius = 6.0;
	_selectedSegmentIndex = -1;
	
	_ringLayer = [CAShapeLayer layer];
	_linesLayer = [CAShapeLayer layer];
	_segmentLayer = [CAShapeLayer layer];
	_arcTexts = [NSMutableArray array];
	_theSegments = [NSMutableArray array];
	
	_ringLayer.fillColor = _ringFillColor.CGColor;
	_ringLayer.strokeColor = NULL;
	
	_linesLayer.fillColor = NULL;
	_linesLayer.strokeColor = _ringStrokeColor.CGColor;
	_linesLayer.lineWidth = 1.0;
	
	_segmentLayer.fillColor = _segmentColor.CGColor;
	_segmentLayer.strokeColor = UIColor.clearColor.CGColor;
	
	_segmentLayer.shadowColor = UIColor.blackColor.CGColor;
	_segmentLayer.shadowOpacity = 0.20;
	_segmentLayer.shadowOffset = CGSizeZero;
	_segmentLayer.shadowRadius = 2.0;

	[self.layer addSublayer:_ringLayer];
	[self.layer addSublayer:_linesLayer];
	[self.layer addSublayer:_segmentLayer];
	
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimation)];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	_displayLink.paused = YES;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (!CGRectEqualToRect(_myBounds, self.bounds)) {
		_myBounds = self.bounds;
		[self updateLayout];
	}
}

- (void)updateLayout {
	double r1 = self.bounds.size.width * 0.5;
	double r2 = r1 - self.ringWidth;
	
	CGPoint cntr = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	
	UIBezierPath *p1 = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
	UIBezierPath *p2 = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, self.ringWidth, self.ringWidth)];
	[p1 appendPath:p2];
	p1.usesEvenOddFillRule = YES;
	self.ringLayer.path = p1.CGPath;
	self.ringLayer.fillRule = kCAFillRuleEvenOdd;
	
	for (UIView *v in self.arcTexts) {
		[v removeFromSuperview];
	}
	self.arcTexts = [NSMutableArray array];
	
	if (self.theSegments.count > 0) {
		UIBezierPath *pOuter = [UIBezierPath bezierPath];
		UIBezierPath *pInner = [UIBezierPath bezierPath];
		UIBezierPath *pLines = [UIBezierPath bezierPath];
		
		double d1 = -1.0;
		double d2 = -1.0;
		
		for (int i = 0; i < self.theSegments.count; i++) {
			Segment *segment = self.theSegments[i];
			d1 = [self radiansFromDegrees:segment.startAngleInDegrees];
			d2 = [self radiansFromDegrees:segment.endAngleInDegrees];
			
			d1 += [self radiansFromDegrees:self.originDegrees];
			d2 += [self radiansFromDegrees:self.originDegrees];
			
			[pOuter addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pInner addArcWithCenter:cntr radius:r2 startAngle:d1 endAngle:d2 clockwise:YES];
			
			[pLines moveToPoint:pOuter.currentPoint];
			[pLines addLineToPoint:pInner.currentPoint];
			
			UIBezierPath *pSeg = [UIBezierPath bezierPath];
			[pSeg addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pSeg addArcWithCenter:cntr radius:r2 startAngle:d2 endAngle:d1 clockwise:NO];
			[pSeg closePath];
			segment.path = pSeg;
			
			ArcTextView *v = [[ArcTextView alloc] init];
			v.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:v];
			
			[NSLayoutConstraint activateConstraints:@[
				[v.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0],
				[v.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.0],
				[v.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.0],
				[v.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0.0]
			]];
			
			v.text = segment.title;
			v.startAngle = [self radiansFromDegrees:(segment.midAngleInDegrees + self.originDegrees)];
			v.radius = r1 - self.ringWidth / 2.0;
			v.textColor = self.textColor;
			v.font = self.font;
			[self.arcTexts addObject:v];
		}
		
		if (self.theSegments.lastObject && floor(self.theSegments.lastObject.endAngleInDegrees) < 360.0) {
			NSLog(@"add last line");
			d2 = [self radiansFromDegrees:360.0];
			[pOuter addArcWithCenter:cntr radius:r1 startAngle:d1 endAngle:d2 clockwise:YES];
			[pInner addArcWithCenter:cntr radius:r2 startAngle:d1 endAngle:d2 clockwise:YES];
			[pLines moveToPoint:pOuter.currentPoint];
			[pLines addLineToPoint:pInner.currentPoint];
		}
		
		[pLines appendPath:[UIBezierPath bezierPathWithOvalInRect:self.bounds]];
		[pLines appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, self.ringWidth, self.ringWidth)]];
		
		self.linesLayer.path = pLines.CGPath;
		
		self.segmentLayer.transform = CATransform3DIdentity;
		self.segmentLayer.frame = self.bounds;
		
		self.segmentLayer.transform = CATransform3DMakeRotation([self radiansFromDegrees:self.originDegrees], 0, 0, 1);
		
		[self updateSegment:0];
	}
}

- (double)radiansFromDegrees:(double)degrees {
	return degrees * M_PI / 180.0;
}
// Helper method to convert degrees to radians
- (double)doubleToRadians:(double)degrees {
	return degrees * M_PI / 180.0;
}

- (void)drawSegmentWithStartDegree:(double)startDegree endDegree:(double)endDegree {
	// Convert degrees to radians
	double startAngle = [self doubleToRadians:startDegree + 1.0];
	double endAngle = [self doubleToRadians:endDegree - 1.0];
	
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
	self.sourceDegreeStart = self.theSegments[fromSeg].startAngleInDegrees;
	self.sourceDegreeEnd = self.theSegments[fromSeg].endAngleInDegrees;
	self.targetDegreeStart = self.theSegments[toSeg].startAngleInDegrees;
	self.targetDegreeEnd = self.theSegments[toSeg].endAngleInDegrees;
	
	double g1 = self.theSegments[fromSeg].midAngleInDegrees;
	double g2 = self.theSegments[toSeg].midAngleInDegrees;
	double absD = fabs(g2 - g1);
	
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
		[self drawSegmentWithStartDegree:self.theSegments[self.m_selectedSegment].startAngleInDegrees
							   endDegree:self.theSegments[self.m_selectedSegment].endAngleInDegrees];
		return;
	}
	
	// Apply ease-in-ease-out algorithm
	CGFloat easedT = [self easeInOut:(CGFloat)t];
	
	double newSt = self.sourceDegreeStart + self.startDegreeDist * easedT;
	double newEnd = self.sourceDegreeEnd + self.endDegreeDist * easedT;
	[self drawSegmentWithStartDegree:newSt endDegree:newEnd];
}

- (CGFloat)easeInOut:(CGFloat)t {
	return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

- (void)setSelectedSegmentIndex:(NSInteger)index {
	[self setSelectedSegmentIndex:index animated:NO];
}
- (void)setSelectedSegmentIndex:(NSInteger)index animated:(BOOL)animated {
	if (animated && self.m_selectedSegment > -1) {
		[self animateSegmentFrom:self.m_selectedSegment to:index];
	} else {
		[self updateSegment:index];
	}
	self.m_selectedSegment = index;
}

- (void)updateSegment:(NSInteger)index {
	[self drawSegmentWithStartDegree:_theSegments[index].startAngleInDegrees endDegree:_theSegments[index].endAngleInDegrees];
	self.m_selectedSegment = index;
}

- (void)setTitles:(NSArray<NSString *> *)titles {
	_titles = titles;
	
	self.theSegments = [NSMutableArray array];
	double segSize = 360.0 / (double)titles.count;
	double d = 0.0;
	
	for (NSInteger i = 0; i < titles.count; i++) {
		NSString *t = titles[i];
		
		Segment *seg = [[Segment alloc] init];
		seg.title = t;
		seg.startAngleInDegrees = d;
		
		if (self.segmentWidthsInDegrees.count > 0) {
			if (i == titles.count - 1 && self.segmentWidthsInDegrees.count < titles.count) {
				d = 360.0;
			} else {
				d += [self.segmentWidthsInDegrees[i] doubleValue];
			}
		} else {
			d += segSize;
		}
		
		seg.endAngleInDegrees = d;
		[self.theSegments addObject:seg];
	}
	
	[self updateLayout];
}

// Segment widths property
- (void)setSegmentWidthsInDegrees:(NSArray<NSNumber *> *)segmentWidthsInDegrees {
	_segmentWidthsInDegrees = segmentWidthsInDegrees;
	
	if (self.theSegments.count > 0) {
		if (segmentWidthsInDegrees.count < self.theSegments.count - 1) {
			// Handle the error case
			// You may want to add an error handling mechanism instead of returning
			return;
		}
		
		double d = 0.0;
		for (NSInteger i = 0; i < self.theSegments.count; i++) {
			Segment *segment = self.theSegments[i];
			segment.startAngleInDegrees = d;
			
			if (i == self.theSegments.count - 1 && segmentWidthsInDegrees.count < self.theSegments.count) {
				segment.endAngleInDegrees = 360.0;
			} else {
				d += segmentWidthsInDegrees[i].doubleValue;
				segment.endAngleInDegrees = d;
			}
		}
		
		[self updateLayout];
	}
}

// Font property
- (void)setFont:(UIFont *)font {
	_font = font;
	for (UILabel *v in self.arcTexts) {
		v.font = font;
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

// Ring fill color property
- (void)setRingFillColor:(UIColor *)ringFillColor {
	_ringFillColor = ringFillColor;
	self.ringLayer.fillColor = ringFillColor.CGColor;
}

// Ring stroke color property
- (void)setRingStrokeColor:(UIColor *)ringStrokeColor {
	_ringStrokeColor = ringStrokeColor;
	self.linesLayer.strokeColor = ringStrokeColor.CGColor;
}

// Property for originDegrees
- (void)setOriginDegrees:(double)originDegrees {
	_originDegrees = originDegrees;
	[self updateLayout];
}

// Property for ringWidth
- (void)setRingWidth:(CGFloat)ringWidth {
	_ringWidth = ringWidth;
	[self updateLayout];
}

// Property for cornerRadius
- (void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	[self updateLayout];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (self.displayLink && !self.displayLink.isPaused) {
		return;
	}
	
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInView:self];
	
	for (NSInteger i = 0; i < self.theSegments.count; i++) {
		Segment *segment = self.theSegments[i];
		if ([segment.path containsPoint:p]) {
			[self animateSegmentFrom:self.m_selectedSegment to:i];
			self.m_selectedSegment = i;
			[self sendActionsForControlEvents:UIControlEventValueChanged];
			break;
		}
	}
}

@end

@implementation ArcTextView

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
	self.backgroundColor = [UIColor clearColor];
	self.text = @"Text Along Arc";
	self.startAngle = -M_PI_2; // Top of the circle
	self.radius = 100.0;
	self.font = [UIFont systemFontOfSize:16];
	self.textColor = [UIColor blackColor];
}

- (void)setRadius:(CGFloat)radius {
	_radius = radius;
	[self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font {
	_font = font;
	[self setNeedsDisplay];
}

- (void)setTextColor:(UIColor *)textColor {
	_textColor = textColor;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (!context) return;
	
	// Center of the arc
	CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	
	// Attributes for the text
	NSDictionary *attributes = @{
		NSFontAttributeName: self.font,
		NSForegroundColorAttributeName: self.textColor
	};
	
	// Total arc length
	CGFloat totalArcLength = 0;
	for (NSUInteger i = 0; i < self.text.length; i++) {
		NSString *charString = [self.text substringWithRange:NSMakeRange(i, 1)];
		CGSize charSize = [charString sizeWithAttributes:attributes];
		totalArcLength += charSize.width;
	}
	
	CGFloat totalArcAngle = totalArcLength / self.radius;
	
	// Adjust starting angle to center the text
	CGFloat currentAngle = self.startAngle - totalArcAngle / 2;
	
	// Draw each character
	for (NSUInteger i = 0; i < self.text.length; i++) {
		NSString *charString = [self.text substringWithRange:NSMakeRange(i, 1)];
		CGSize charSize = [charString sizeWithAttributes:attributes];
		
		CGFloat halfCharAngle = (charSize.width / self.radius) / 2;
		CGFloat charAngle = currentAngle + halfCharAngle;
		
		// Calculate character position
		CGFloat x = center.x + self.radius * cos(charAngle);
		CGFloat y = center.y + self.radius * sin(charAngle);
		
		CGContextSaveGState(context);
		
		// Move to position and rotate context
		CGContextTranslateCTM(context, x, y);
		CGContextRotateCTM(context, charAngle + M_PI_2);
		
		// Draw the character
		[charString drawAtPoint:CGPointMake(-charSize.width / 2, -charSize.height / 2) withAttributes:attributes];
		
		CGContextRestoreGState(context);
		
		// Update current angle
		currentAngle += charSize.width / self.radius;
	}
}

@end
