//
//  SMAttachmentsPanelItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentItem.h"
#import "SMAttachmentsPanelItemView.h"

@implementation SMAttachmentsPanelItemView

- (void)setSelected:(BOOL)flag {
	[super setSelected: flag];
 
	NSAssert(_box != nil, @"no box set");

	NSColor *fillColor = flag? [NSColor selectedControlColor] : [NSColor controlBackgroundColor];
 
	[_box setFillColor:fillColor];
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	if([theEvent clickCount] == 2) {
		NSLog(@"%s: double click", __func__);
		//[NSApp sendAction:@selector(collectionItemViewDoubleClick:) to:nil from:[self object]];
		
		SMAttachmentItem *attachmentItem = [self representedObject];

		NSLog(@"%s: attachment item %@", __func__, attachmentItem.fileName);
	}
}

@end
