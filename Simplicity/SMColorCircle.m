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
	NSPoint point = NSMakePoint(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height/2);
	float spotSide = self.bounds.size.width/2;
	float halfSide = spotSide / 1.5;
	NSRect spotRect = NSMakeRect(point.x - halfSide, point.y - halfSide, spotSide, spotSide);
	[[NSColor blackColor] set];
	[[NSBezierPath bezierPathWithOvalInRect: spotRect] fill];
}

@end
