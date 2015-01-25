//
//  SMAttachmentsPanelItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsPanelItemView.h"

@implementation SMAttachmentsPanelItemView

- (void)setSelected:(BOOL)flag {
	[super setSelected: flag];
 
	NSAssert(_box != nil, @"no box set");

	NSColor *fillColor = flag? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
 
	[_box setFillColor:fillColor];
}

@end
