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
		NSRect bounds = self.bounds;
		CGFloat maxX = NSMaxX(bounds);
		CGFloat minX = NSMinX(bounds);
		CGFloat maxY = NSMaxY(bounds);
		
		NSBezierPath *result = [NSBezierPath bezierPath];
		
		[result moveToPoint:NSMakePoint(maxX, maxY)];
		[result lineToPoint:NSMakePoint(minX, maxY)];
		[result lineToPoint:NSMakePoint(minX + 2, maxY - 5)];
		[result lineToPoint:NSMakePoint(minX, maxY - 10)];
		[result lineToPoint:NSMakePoint(maxX, maxY - 10)];
		[result closePath];
		
		NSColor *color = _bookmarkColors[0];
		
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[color highlightWithLevel:0.45] endingColor:color];
		
		[gradient drawInBezierPath:result angle:-90.00];
	}
}

@end
