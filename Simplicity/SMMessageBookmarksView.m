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
			CGFloat maxX = NSMaxX(bounds);
			CGFloat minX = NSMinX(bounds);
			CGFloat maxY = originY - step * i;
			
			NSBezierPath *result = [NSBezierPath bezierPath];
			
			[result moveToPoint:NSMakePoint(maxX, maxY)];
			[result lineToPoint:NSMakePoint(minX, maxY)];
			[result lineToPoint:NSMakePoint(minX + 2, maxY - 5)];
			[result lineToPoint:NSMakePoint(minX, maxY - 10)];
			[result lineToPoint:NSMakePoint(maxX, maxY - 10)];
			[result closePath];
			
			NSColor *color = _bookmarkColors[i];
			
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[color highlightWithLevel:0.45] endingColor:color];
			
			[gradient drawInBezierPath:result angle:-90.00];
		}
	}
}

@end
