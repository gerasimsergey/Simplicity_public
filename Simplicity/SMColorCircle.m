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

#if 0 // enable to draw the enclosing rect
	[[NSColor grayColor] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
#endif

	CGFloat spotSide = rect.size.width/2.0;
	NSPoint point = NSMakePoint(NSMidX(rect), NSMidY(rect));
	NSRect spotRect = NSMakeRect(point.x - spotSide/2 + 1, point.y - spotSide/2 + 2, spotSide, spotSide);

	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: spotRect] fill];
}

@end
