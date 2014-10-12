//
//  SMTokenField.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 10/12/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMTokenField.h"

@implementation SMTokenField

// See these topics for explanation:
//
// http://stackoverflow.com/questions/10463680/how-to-let-nstextfield-grow-with-the-text-in-auto-layout
// http://stackoverflow.com/questions/24618703/automatically-wrap-nstextfield-using-auto-layout
// http://stackoverflow.com/questions/3212279/nstableview-row-height-based-on-nsstrings

-(NSSize)intrinsicContentSize
{
	if(![self.cell wraps])
		return [super intrinsicContentSize];

	NSRect frame = [self frame];
	
	frame.size.height = CGFLOAT_MAX;
	
	NSSize sizeToFit = [self.cell cellSizeForBounds:frame];

	return NSMakeSize(-1, sizeToFit.height);
}

- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	[self invalidateIntrinsicContentSize];
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	[self invalidateIntrinsicContentSize];
}

@end
