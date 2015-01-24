//
//  SMAttachmentsPanelItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsPanelItemView.h"

@implementation SMAttachmentsPanelItemView

- (void) awakeFromNib {
	NSAssert([[[self view] subviews][0] isKindOfClass:[NSBox class]], @"view is not an NSBox");

	NSBox *view = [[self view] subviews][0];

	[view setTitlePosition:NSNoTitle];
	[view setBoxType:NSBoxCustom];
	[view setCornerRadius:8.0];
	[view setBorderType:NSNoBorder];
}

- (void)setSelected:(BOOL)flag {
	[super setSelected: flag];
 
	NSAssert([[[self view] subviews][0] isKindOfClass:[NSBox class]], @"view is not an NSBox");

	NSBox *view = [[self view] subviews][0];
	NSColor *fillColor = flag? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
 
	[view setFillColor:fillColor];
}

@end
