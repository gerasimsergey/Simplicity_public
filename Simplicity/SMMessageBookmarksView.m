//
//  SMMessageBookmarksView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/7/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageBookmarksView.h"

@implementation SMMessageBookmarksView {
	NSArray *_bookmarkColors;
}

- (NSArray*)bookmarkColors {
	return _bookmarkColors;
}

- (void)setBookmarkColors:(NSArray*)bookmarkColors {
	_bookmarkColors = bookmarkColors;

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	if(_bookmarkColors != nil && _bookmarkColors.count > 0) {
		const NSRect bounds = self.bounds;
		const CGFloat originY = NSMaxY(bounds);
		const CGFloat step = 12;
		
		for(NSUInteger i = 0, n = MIN(_bookmarkColors.count, 4); i < n; i++) {
			CGFloat minX = NSMinX(bounds);
			CGFloat maxY = originY - step * i;
			CGFloat sz = step;
			
			NSRect circleBounds = NSMakeRect(minX, maxY - sz + 1, sz, sz);
			NSColor *color = _bookmarkColors[i];
			
			CGFloat circleRadius = circleBounds.size.height / 2.5;
			NSRect circleRect = NSMakeRect(NSMidX(circleBounds) - circleRadius, NSMidY(circleBounds) - circleRadius, circleRadius * 2, circleRadius * 2);
			NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[color highlightWithLevel:0.45] endingColor:color];
			
			[gradient drawInBezierPath:circlePath angle:-90.00];

		}
	}
}

@end
