//
//  ArcTextView.m
//  CircularSegmentedControl
//
//  Created by Don Mag on 12/11/24.
//

#import "ArcTextView.h"

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
	self.startAngle = 0.0;
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
		
		// Calculate the position for the character along the arc
		CGFloat halfCharAngle = (charSize.width / self.radius) / 2;
		CGFloat charAngle = currentAngle + halfCharAngle;
		
		// Calculate the character's position
		CGFloat x = center.x + self.radius * cos(charAngle);
		CGFloat y = center.y + self.radius * sin(charAngle);
		
		// Save the context's state
		CGContextSaveGState(context);

		// Move to the character's position and rotate the context
		CGContextTranslateCTM(context, x, y);
		// Rotate to align with the arc
		CGContextRotateCTM(context, charAngle + M_PI_2);
		
		// Draw the character
		[charString drawAtPoint:CGPointMake(-charSize.width / 2, -charSize.height / 2) withAttributes:attributes];
		
		// Restore the context's state
		CGContextRestoreGState(context);
		
		// Update current angle
		currentAngle += charSize.width / self.radius;
	}
}

@end
