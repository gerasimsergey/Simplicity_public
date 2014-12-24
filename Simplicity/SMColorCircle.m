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
    
	NSBezierPath* path = [NSBezierPath bezierPath];
 
	[[NSColor redColor] setStroke];
	[[NSColor redColor] setFill];

	[path appendBezierPathWithOvalInRect:dirtyRect];
	
	[path stroke];
	[path fill];
}

@end
