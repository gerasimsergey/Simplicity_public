//
//  SMTokenField.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 10/12/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMTokenField.h"

@implementation SMTokenField

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


-(NSSize)intrinsicContentSize
{
	if ( ![self.cell wraps] ) {
		return [super intrinsicContentSize];
	}

	NSRect frame = [self frame];
	
	frame.size.height = CGFLOAT_MAX;
	
	CGFloat height = [self.cell cellSizeForBounds:frame].height;
	CGFloat width = -1;

	return NSMakeSize(width, height);
}

// you need to invalidate the layout on text change, else it wouldn't grow by changing the text
- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	[self invalidateIntrinsicContentSize];
}

@end
