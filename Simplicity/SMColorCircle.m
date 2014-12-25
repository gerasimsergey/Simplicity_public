//
//  SMColorCircle.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 12/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMColorCircle.h"

@implementation SMColorCircle

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	NSRect rect = self.bounds;

	CGFloat spotSide = rect.size.width/2.0;
	NSPoint point = NSMakePoint(NSMidX(rect) - spotSide/2, NSMidY(rect) - spotSide/2);

	NSRect outerSpotRect = NSMakeRect(point.x, point.y + 1, spotSide + 2, spotSide + 2);
	
	[[NSColor grayColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: outerSpotRect] fill];

	NSRect innerSpotRect = NSMakeRect(point.x + 1, point.y + 2, spotSide, spotSide);

	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: innerSpotRect] fill];
}

@end
