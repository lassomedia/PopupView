/*
 * PopupView
 * SNPopupView.m
 *
 * Copyright (c) Yuichi YOSHIDA, 10/12/07.
 * All rights reserved.
 * 
 * BSD License
 *
 * Redistribution and use in source and binary forms, with or without modification, are 
 * permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice, this list of
 *  conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, this list
 *  of conditions and the following disclaimer in the documentation and/or other materia
 * ls provided with the distribution.
 * - Neither the name of the "Yuichi Yoshida" nor the names of its contributors may be u
 * sed to endorse or promote products derived from this software without specific prior 
 * written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY E
 * XPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES O
 * F MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SH
 * ALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENT
 * AL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROC
 * UREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS I
 * NTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRI
 * CT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF T
 * HE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SNPopupView.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

@interface TouchPeekView : UIView {
	SNPopupView *__unsafe_unretained delegate;
}
@property (nonatomic, unsafe_unretained) SNPopupView *delegate;
@end

@interface SNPopupView(Private)
- (void)popup;
@end
	
@implementation TouchPeekView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([delegate shouldBeDismissedFor:touches withEvent:event])
		[delegate dismissModal];
}

@end

@implementation SNPopupView

@synthesize title, image, contentView, delegate, shadowOffset, contentOffset, rootArrowOverlap, rootArrowSize, forceDirection, attributedTitle;

#pragma mark - Prepare

- (void)setupGradientColors {		
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	CGFloat colors[] =
	{
		155.0 / 255.0, 155.0 / 255.0, 155.0 / 255.0, ALPHA,
		70.0 / 255.0, 70.0 / 255.0, 70.0 / 255.0, ALPHA,
	};
	gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
	
	CGFloat colors2[] =
	{
		20.0 / 255.0, 20.0 / 255.0, 20.0 / 255.0, ALPHA,
		0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0, ALPHA,
	};
	gradient2 = CGGradientCreateWithColorComponents(rgb, colors2, NULL, sizeof(colors2)/(sizeof(colors2[0])*4));
	CGColorSpaceRelease(rgb);
}

- (id) init {
    self = [super init];
    if (self) {
        self.shadowOffset = SHADOW_OFFSET;
        self.contentOffset = CONTENT_OFFSET;
        self.rootArrowSize = POPUP_ROOT_SIZE;
        self.rootArrowOverlap = POPUP_ROOT_Y_OVERLAP;
    }
    return self;
}

- (id) initWithString:(NSString*)newValue {
	return [self initWithString:newValue withFontOfSize:DEFAULT_TITLE_SIZE];
}

- (id) initWithString:(NSString*)newValue withFontOfSize:(float)newFontSize {
	self = [self init];
	if (self != nil) {
		title = [newValue copy];
		
        // Initialization code
		[self setBackgroundColor:[UIColor clearColor]];
		
		fontSize = newFontSize;
		UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
		
		CGSize titleRenderingSize = [title sizeWithFont:font];
		
		contentBounds = CGRectZero;
		contentBounds.size = titleRenderingSize;
		
		[self setupGradientColors];
		
	}
	return self;
}

- (id)initWithAttributedString:(NSAttributedString *)stringValue {
 	self = [self init];
	if (self != nil) {
		attributedTitle = [stringValue copy];
		
        // Initialization code
		[self setBackgroundColor:[UIColor clearColor]];
		
		contentBounds = CGRectZero;
		contentBounds.size = stringValue.size;
		
		[self setupGradientColors];
	}
	return self;
}

- (id) initWithImage:(UIImage*)newImage {
	self = [self init];
	if (self != nil) {
		image = newImage;
		
        // Initialization code
		[self setBackgroundColor:[UIColor clearColor]];
		
		contentBounds = CGRectZero;
		contentBounds.size = image.size;
		
		[self setupGradientColors];
		
	}
	return self;
}

- (id) initWithContentView:(UIView*)newContentView contentSize:(CGSize)contentSize {
	self = [self init];
	if (self != nil) {
		contentView = newContentView;
		
        // Initialization code
		[self setBackgroundColor:[UIColor clearColor]];
		
		contentBounds = CGRectZero;
		contentBounds.size = contentSize;
		
		[self setupGradientColors];
	}
	return self;
}

- (void)addTarget:(id)newTarget action:(SEL)newAction {
	if ([newTarget respondsToSelector:newAction]) {
		target = newTarget;
		action = newAction;
	}
}

// simple convenience method
- (void)setBackgroundBoxImage:(UIImage *)backgroundBoxImage backgroundArrowImage:(UIImage *)backgroundArrowImage {
    self.backgroundBoxImage = backgroundBoxImage;
    self.backgroundArrowImage = backgroundArrowImage;
    // images don't use the shadow offset
    self.shadowOffset = CGSizeZero;
    // or the root arrow size
    self.rootArrowSize = CGSizeZero;
}

#pragma mark - Present modal

- (void)createAndAttachTouchPeekView {
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];

	[peekView removeFromSuperview];
	peekView = nil;
	peekView = [[TouchPeekView alloc] initWithFrame:window.frame];
	[peekView setDelegate:self];
	
	[window addSubview:peekView];
}

- (void)presentModalAtPoint:(CGPoint)p inView:(UIView*)inView {
	animatedWhenAppering = YES;
	[self createAndAttachTouchPeekView];
	[self showAtPoint:[inView convertPoint:p toView:[[UIApplication sharedApplication] keyWindow]] inView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)presentModalAtPoint:(CGPoint)p inView:(UIView*)inView animated:(BOOL)animated {
	animatedWhenAppering = animated;
	[self createAndAttachTouchPeekView];
	[self showAtPoint:[inView convertPoint:p toView:[[UIApplication sharedApplication] keyWindow]] inView:[[UIApplication sharedApplication] keyWindow] animated:animated];
}

#pragma mark - Show as normal view

- (void)showAtPoint:(CGPoint)p inView:(UIView*)inView {
	[self showAtPoint:p inView:inView animated:NO];
}

- (void)showAtPoint:(CGPoint)p inView:(UIView*)inView animated:(BOOL)animated {
    
	if ((p.y - contentBounds.size.height - self.rootArrowSize.height - 2 * self.contentOffset.height - self.shadowOffset.height) < 0) {
		direction = SNPopupViewDown;
	}
	else {
		direction = SNPopupViewUp;
	}
    
    if (self.forceDirection) {
        direction = self.forceDirection;
    }
	
	if (direction & SNPopupViewUp) {

		pointToBeShown = p;
		
		// calc content area
        // the x starting point is the click point minus half the contentWidth
		contentRect.origin.x = p.x - (int)contentBounds.size.width/2;
        // y of contentRect = content offset - arrow height - content height
		contentRect.origin.y = p.y - self.contentOffset.height - self.rootArrowSize.height - contentBounds.size.height;
		contentRect.size = contentBounds.size;
		
		// calc popup area
		popupBounds.origin = CGPointMake(0, 0);
		popupBounds.size.width = contentBounds.size.width + self.contentOffset.width + self.contentOffset.width;
		popupBounds.size.height = contentBounds.size.height + self.contentOffset.height + self.contentOffset.height + self.rootArrowSize.height + (self.rootArrowOverlap > 0 ? self.rootArrowOverlap : 0);
		
		popupRect.origin.x = contentRect.origin.x - self.contentOffset.width;
		popupRect.origin.y = contentRect.origin.y - self.contentOffset.height;
		popupRect.size = popupBounds.size;
		
		// calc self size and rect
		viewBounds.origin = CGPointMake(0, 0);
		viewBounds.size.width = popupRect.size.width + self.shadowOffset.width + self.shadowOffset.width;
		viewBounds.size.height = popupRect.size.height + self.shadowOffset.height + self.shadowOffset.height;
		
		viewRect.origin.x = popupRect.origin.x - self.shadowOffset.width;
		viewRect.origin.y = popupRect.origin.y - self.shadowOffset.height;
		viewRect.size = viewBounds.size;

		float left_viewRect = viewRect.origin.x + viewRect.size.width;
		
		// calc horizontal offset
		if (viewRect.origin.x < 0) {
			direction = direction | SNPopupViewRight;
			horizontalOffset = viewRect.origin.x;
			
			if (viewRect.origin.x - horizontalOffset < pointToBeShown.x - HORIZONTAL_SAFE_MARGIN) {
			}
			else {
				pointToBeShown.x = HORIZONTAL_SAFE_MARGIN;
			}
			viewRect.origin.x -= horizontalOffset;
			contentRect.origin.x -= horizontalOffset;
			popupRect.origin.x -= horizontalOffset;
		}
		else if (left_viewRect > inView.frame.size.width) {
			direction = direction | SNPopupViewLeft;
			horizontalOffset = inView.frame.size.width - left_viewRect;
			
			if (left_viewRect + horizontalOffset > pointToBeShown.x + HORIZONTAL_SAFE_MARGIN) {
			}
			else {
				pointToBeShown.x = inView.frame.size.width - HORIZONTAL_SAFE_MARGIN;
			}
			viewRect.origin.x += horizontalOffset;
			contentRect.origin.x += horizontalOffset;
			popupRect.origin.x += horizontalOffset;
		}
	}
	else {
		pointToBeShown = p;
		
		// calc content area
		contentRect.origin.x = p.x - (int)contentBounds.size.width/2;
		contentRect.origin.y = p.y + self.contentOffset.height + self.rootArrowSize.height;
		contentRect.size = contentBounds.size;
		
		// calc popup area
		popupBounds.origin = CGPointMake(0, 0);
		popupBounds.size.width = contentBounds.size.width + self.contentOffset.width + self.contentOffset.width;
		popupBounds.size.height = contentBounds.size.height + self.contentOffset.height + self.contentOffset.height + self.rootArrowSize.height + (self.rootArrowOverlap > 0 ? self.rootArrowOverlap : 0);
		
		popupRect.origin.x = contentRect.origin.x - self.contentOffset.width;
		popupRect.origin.y = contentRect.origin.y - self.contentOffset.height - self.rootArrowSize.height - self.rootArrowOverlap;
		popupRect.size = popupBounds.size;
		
		// calc self size and rect
		viewBounds.origin = CGPointMake(0, 0);
		viewBounds.size.width = popupRect.size.width + self.shadowOffset.width + self.shadowOffset.width;
		viewBounds.size.height = popupRect.size.height + self.shadowOffset.height + self.shadowOffset.height;
		
		viewRect.origin.x = popupRect.origin.x - self.shadowOffset.width;
		viewRect.origin.y = popupRect.origin.y - self.shadowOffset.height;
		viewRect.size = viewBounds.size;
		
		float left_viewRect = viewRect.origin.x + viewRect.size.width;
		
		// calc horizontal offset
		if (viewRect.origin.x < 0) {
			direction = direction | SNPopupViewRight;
			horizontalOffset = viewRect.origin.x;
			
			if (viewRect.origin.x - horizontalOffset < pointToBeShown.x - HORIZONTAL_SAFE_MARGIN) {
			}
			else {
				pointToBeShown.x = HORIZONTAL_SAFE_MARGIN;
			}
			viewRect.origin.x -= horizontalOffset;
			contentRect.origin.x -= horizontalOffset;
			popupRect.origin.x -= horizontalOffset;
		}
		else if (left_viewRect > inView.frame.size.width) {
			direction = direction | SNPopupViewLeft;
			horizontalOffset = inView.frame.size.width - left_viewRect;
			
			if (left_viewRect + horizontalOffset > pointToBeShown.x + HORIZONTAL_SAFE_MARGIN) {
			}
			else {
				pointToBeShown.x = inView.frame.size.width - HORIZONTAL_SAFE_MARGIN;
			}
			viewRect.origin.x += horizontalOffset;
			contentRect.origin.x += horizontalOffset;
			popupRect.origin.x += horizontalOffset;
		}
	}
	
	// offset
	contentRect.origin.x -= viewRect.origin.x;
	contentRect.origin.y -= viewRect.origin.y;
	popupRect.origin.x -= viewRect.origin.x;
	popupRect.origin.y -= viewRect.origin.y;
	pointToBeShown.x -= viewRect.origin.x;
	pointToBeShown.y -= viewRect.origin.y;
	
	BOOL isAlreadyShown = (self.superview == inView);
	
	if (isAlreadyShown) {
		[self setNeedsDisplay];
		
		
		if (animated) {
			[UIView beginAnimations:@"move" context:nil];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		}
		self.frame = viewRect;
		if (animated) {
			[UIView commitAnimations];
		}
	}
	else {
		// set frame
		[inView addSubview:self];
		self.frame = viewRect;
		
		
		if (contentView) {
			[self addSubview:contentView];
			[contentView setFrame:contentRect];
		}
		
		// popup
		if (animated)
			[self popup];
	}
}

#pragma mark - Core Animation call back

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	[self removeFromSuperview];
}

#pragma mark - Make CoreAnimation object

- (CAKeyframeAnimation*)getAlphaAnimationForPopup {
	
	CAKeyframeAnimation *alphaAnimation = [CAKeyframeAnimation	animationWithKeyPath:@"opacity"];
	alphaAnimation.removedOnCompletion = NO;
	alphaAnimation.values = [NSArray arrayWithObjects:
							 [NSNumber numberWithFloat:0],
							 [NSNumber numberWithFloat:0.7],
							 [NSNumber numberWithFloat:1],
							 nil];
	alphaAnimation.keyTimes = [NSArray arrayWithObjects:
							   [NSNumber numberWithFloat:0],
							   [NSNumber numberWithFloat:0.1],
							   [NSNumber numberWithFloat:1],
							   nil];
	return alphaAnimation;
}

- (CAKeyframeAnimation*)getPositionAnimationForPopup {
	
	float r1 = 0.1;
	float r2 = 1.4;
	float r3 = 1;
	float r4 = 0.8;
	float r5 = 1;
	
	float y_offset =  (popupRect.size.height/2 - self.rootArrowSize.height);
	
	CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	CATransform3D tm1, tm2, tm3, tm4, tm5;
	
	if (direction & SNPopupViewUp) {
		if (direction & SNPopupViewLeft)
			horizontalOffset = -horizontalOffset;
		tm1 = CATransform3DMakeTranslation(horizontalOffset * (1 - r1), y_offset * (1 - r1), 0);
		tm2 = CATransform3DMakeTranslation(horizontalOffset * (1 - r2), y_offset * (1 - r2), 0);
		tm3 = CATransform3DMakeTranslation(horizontalOffset * (1 - r3), y_offset * (1 - r3), 0);
		tm4 = CATransform3DMakeTranslation(horizontalOffset * (1 - r4), y_offset * (1 - r4), 0);
		tm5 = CATransform3DMakeTranslation(horizontalOffset * (1 - r5), y_offset * (1 - r5), 0);
	}
	else {
		if (direction & SNPopupViewLeft)
			horizontalOffset = -horizontalOffset;		
		tm1 = CATransform3DMakeTranslation(horizontalOffset * (1 - r1), -y_offset * (1 - r1), 0);
		tm2 = CATransform3DMakeTranslation(horizontalOffset * (1 - r2), -y_offset * (1 - r2), 0);
		tm3 = CATransform3DMakeTranslation(horizontalOffset * (1 - r3), -y_offset * (1 - r3), 0);
		tm4 = CATransform3DMakeTranslation(horizontalOffset * (1 - r4), -y_offset * (1 - r4), 0);
		tm5 = CATransform3DMakeTranslation(horizontalOffset * (1 - r5), -y_offset * (1 - r5), 0);
	}
	tm1 = CATransform3DScale(tm1, r1, r1, 1);
	tm2 = CATransform3DScale(tm2, r2, r2, 1);
	tm3 = CATransform3DScale(tm3, r3, r3, 1);
	tm4 = CATransform3DScale(tm4, r4, r4, 1);
	tm5 = CATransform3DScale(tm5, r5, r5, 1);
	
	positionAnimation.values = [NSArray arrayWithObjects:
								[NSValue valueWithCATransform3D:tm1],
								[NSValue valueWithCATransform3D:tm2],
								[NSValue valueWithCATransform3D:tm3],
								[NSValue valueWithCATransform3D:tm4],
								[NSValue valueWithCATransform3D:tm5],
								nil];
	positionAnimation.keyTimes = [NSArray arrayWithObjects:
								  [NSNumber numberWithFloat:0.0],
								  [NSNumber numberWithFloat:0.2],
								  [NSNumber numberWithFloat:0.4],
								  [NSNumber numberWithFloat:0.7], 
								  [NSNumber numberWithFloat:1.0],
								  nil];
	return positionAnimation;
}

#pragma mark - Popup and dismiss

- (void)popup {
	
	CAKeyframeAnimation *positionAnimation = [self getPositionAnimationForPopup];
	CAKeyframeAnimation *alphaAnimation = [self getAlphaAnimationForPopup];
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:positionAnimation, alphaAnimation, nil];
	group.duration = POPUP_ANIMATION_DURATION;
	group.removedOnCompletion = YES;
	group.fillMode = kCAFillModeForwards;
	
	[self.layer addAnimation:group forKey:@"hoge"];
}

- (BOOL)shouldBeDismissedFor:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	CGPoint p = [touch locationInView:self];
	return !CGRectContainsPoint(contentRect, p);
}

- (void)dismissModal {
	if ([peekView superview]) 
		[delegate didDismissModal:self];
	[peekView removeFromSuperview];
	
	[self dismiss:animatedWhenAppering];
}

- (void)dismiss:(BOOL)animtaed {
	if (animtaed)
		[self dismiss];
	else {
		[self removeFromSuperview];
	}
}

- (void)dismiss {
	CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	
	float r1 = 1.0;
	float r2 = 0.1;
	
	float y_offset =  (popupRect.size.height/2 - self.rootArrowSize.height);
	
	CAKeyframeAnimation *alphaAnimation = [CAKeyframeAnimation	animationWithKeyPath:@"opacity"];
	alphaAnimation.removedOnCompletion = NO;
	alphaAnimation.values = [NSArray arrayWithObjects:
							 [NSNumber numberWithFloat:1],
							 [NSNumber numberWithFloat:0],
							 nil];
	alphaAnimation.keyTimes = [NSArray arrayWithObjects:
							   [NSNumber numberWithFloat:0],
							   [NSNumber numberWithFloat:1],
							   nil];
	
	CATransform3D tm1, tm2;
	if (direction & SNPopupViewUp) {
		tm1 = CATransform3DMakeTranslation(horizontalOffset * (1 - r1), y_offset * (1 - r1), 0);
		tm2 = CATransform3DMakeTranslation(horizontalOffset * (1 - r2), y_offset * (1 - r2), 0);
	}
	else {	
		tm1 = CATransform3DMakeTranslation(horizontalOffset * (1 - r1), -y_offset * (1 - r1), 0);
		tm2 = CATransform3DMakeTranslation(horizontalOffset * (1 - r2), -y_offset * (1 - r2), 0);
		
	}
	tm1 = CATransform3DScale(tm1, r1, r1, 1);
	tm2 = CATransform3DScale(tm2, r2, r2, 1);
	
	positionAnimation.values = [NSArray arrayWithObjects:
								[NSValue valueWithCATransform3D:tm1],
								[NSValue valueWithCATransform3D:tm2],
								nil];
	positionAnimation.keyTimes = [NSArray arrayWithObjects:
								  [NSNumber numberWithFloat:0],
								  [NSNumber numberWithFloat:1.0],
								  nil];
	
	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.animations = [NSArray arrayWithObjects:positionAnimation, alphaAnimation, nil];
	group.duration = DISMISS_ANIMATION_DURATION;
	group.removedOnCompletion = NO;
	group.fillMode = kCAFillModeForwards;
	group.delegate = self;
	
	[self.layer addAnimation:group forKey:@"hoge"];
}

#pragma mark - Drawing

- (void)makePathCircleCornerRect:(CGRect)rect radius:(float)radius popPoint:(CGPoint)popPoint {
    CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (direction & SNPopupViewUp) {
		rect.size.height -= self.rootArrowSize.height;
		
		// get points
		CGFloat minx = CGRectGetMinX( rect ), midx = CGRectGetMidX( rect ), maxx = CGRectGetMaxX( rect );
		CGFloat miny = CGRectGetMinY( rect ), midy = CGRectGetMidY( rect ), maxy = CGRectGetMaxY( rect );
		
		CGFloat popRightEdgeX = popPoint.x + (int)self.rootArrowSize.width / 2;
		CGFloat popRightEdgeY = maxy;
		
		CGFloat popLeftEdgeX = popPoint.x - (int)self.rootArrowSize.width / 2;
		CGFloat popLeftEdgeY = maxy;
		
		CGContextMoveToPoint(context, minx, midy);
		CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
		CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
		
		
		CGContextAddArcToPoint(context, maxx, maxy, popRightEdgeX, popRightEdgeY, radius);
		CGContextAddLineToPoint(context, popRightEdgeX, popRightEdgeY);
		CGContextAddLineToPoint(context, popPoint.x, popPoint.y);
		CGContextAddLineToPoint(context, popLeftEdgeX, popLeftEdgeY);
		CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
		CGContextAddLineToPoint(context, minx, midy);
		
	}
	else {
		rect.origin.y += self.rootArrowSize.height;
		rect.size.height -= self.rootArrowSize.height;
		
		// get points
		CGFloat minx = CGRectGetMinX( rect ), midx = CGRectGetMidX( rect ), maxx = CGRectGetMaxX( rect );
		CGFloat miny = CGRectGetMinY( rect ), midy = CGRectGetMidY( rect ), maxy = CGRectGetMaxY( rect );
		
		CGFloat popRightEdgeX = popPoint.x + (int)self.rootArrowSize.width / 2;
		CGFloat popRightEdgeY = miny;
		
		CGFloat popLeftEdgeX = popPoint.x - (int)self.rootArrowSize.width / 2;
		CGFloat popLeftEdgeY = miny;
		
		CGContextMoveToPoint(context, minx, midy);
		CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
		CGContextAddLineToPoint(context, popLeftEdgeX, popLeftEdgeY);
		CGContextAddLineToPoint(context, popPoint.x, popPoint.y);
		CGContextAddLineToPoint(context, popRightEdgeX, popRightEdgeY);
		CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
		CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
		CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	}
}

#pragma mark - Override

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if ([self shouldBeDismissedFor:touches withEvent:event] && peekView != nil) {
		[self dismissModal];
		return;
	}
	
	if ([target respondsToSelector:action]) {
        objc_msgSend(target, action, self);
	}
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();

#ifdef _CONFIRM_REGION
	CGContextFillRect(context, rect);
	CGContextSetRGBFillColor(context, 1, 0, 0, 1);
	CGContextFillRect(context, popupRect);
	CGContextSetRGBFillColor(context, 1, 1, 0, 1);
	CGContextFillRect(context, contentRect);
#endif
	
    
    if (!self.backgroundBoxImage || !self.backgroundArrowImage) {
        // draw shadow, and base
        CGContextSaveGState(context);
        
        CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1, ALPHA);
        CGContextSetShadowWithColor (context, CGSizeMake(0, 2), 2, [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]);
        [self makePathCircleCornerRect:popupRect radius:10 popPoint:pointToBeShown];
        CGContextClosePath(context);
        CGContextFillPath(context);
        CGContextRestoreGState(context);
        
        // draw body
        CGContextSaveGState(context);
        [self makePathCircleCornerRect:popupRect radius:10 popPoint:pointToBeShown];
        CGContextClip(context);
        if (direction & SNPopupViewUp) {
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, popupRect.origin.y), CGPointMake(0, popupRect.origin.y + (int)(popupRect.size.height-self.rootArrowSize.height)/2), 0);
            CGContextDrawLinearGradient(context, gradient2, CGPointMake(0, popupRect.origin.y + (int)(popupRect.size.height-self.rootArrowSize.height)/2), CGPointMake(0, popupRect.origin.y + popupRect.size.height-self.rootArrowSize.height), 0);
        }
        else {
            int h = (int)(popupRect.size.height - self.rootArrowSize.height);
            CGContextDrawLinearGradient(context, gradient, CGPointMake(0, popupRect.origin.y + self.rootArrowSize.height), CGPointMake(0, popupRect.origin.y + h/2 + self.rootArrowSize.height), 0);
            CGContextDrawLinearGradient(context, gradient2, CGPointMake(0, popupRect.origin.y + h/2 + self.rootArrowSize.height), CGPointMake(0, popupRect.origin.y + popupRect.size.height), 0);
        }
        CGContextRestoreGState(context);
    } else {
        // draw background image
        UIImage *resizeableBackgroundImage = [self.backgroundBoxImage resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10) resizingMode:UIImageResizingModeStretch ];
        [resizeableBackgroundImage drawInRect:CGRectMake(
                                                         contentRect.origin.x - self.contentOffset.width,
                                                         contentRect.origin.y - self.contentOffset.height,
                                                         contentRect.size.width + (self.contentOffset.width*2),
                                                         contentRect.size.height + (self.contentOffset.height*2)
                                                         )];
        NSInteger XPoint = pointToBeShown.x - ((int)self.backgroundArrowImage.size.width/2);
        
        if (direction & SNPopupViewDown) {
            [self.backgroundArrowImage drawAtPoint:CGPointMake(XPoint, contentRect.origin.y - self.contentOffset.height - self.rootArrowOverlap)];
            // draw arrow
        } else {
            UIImage* flippedArrow = [UIImage imageWithCGImage:self.backgroundArrowImage.CGImage
                                                        scale:1.0 orientation: UIImageOrientationDownMirrored];
            [flippedArrow drawAtPoint:CGPointMake(XPoint, contentRect.origin.y + contentRect.size.height + self.contentOffset.height + self.rootArrowOverlap - flippedArrow.size.height)];
        }
    }
    
    
	
	// draw content
	if ([title length]) {
        CGContextSetRGBFillColor(context, 1, 1, 1, 1);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        [title drawInRect:contentRect withFont:font];
	}
    if ([attributedTitle length]) {
        [attributedTitle drawInRect:contentRect];
    }
	if (image) {
		[image drawInRect:contentRect];
	}
}

#pragma mark - dealloc

- (void)dealloc {
	CGGradientRelease(gradient);
	CGGradientRelease(gradient2);
	
}


@end
