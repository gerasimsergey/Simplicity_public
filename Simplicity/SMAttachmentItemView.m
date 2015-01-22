//
//  SMAttachmentItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/21/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentItemView.h"

@implementation SMAttachmentItemView

- (void) awakeFromNib {
	NSBox *view = (NSBox*)[self view];

	[view setTitlePosition:NSNoTitle];
	[view setBoxType:NSBoxCustom];
	[view setCornerRadius:8.0];
	[view setBorderType:NSLineBorder];
}

- (void)setSelected:(BOOL)flag {
//	[super setSelected: flag];
	
//	NSBox *view = (NSBox*) [self view];

 /*
	NSColor *color;
	NSColor *lineColor;
 
	if (flag) {
		color       = [NSColor selectedControlColor];
		lineColor   = [NSColor blackColor];
	} else {
		color       = [NSColor controlBackgroundColor];
		lineColor   = [NSColor controlBackgroundColor];
	}
	[view setBorderColor:lineColor];
  [view setFillColor:color];
  */
//	NSLog(@"%s: view %@", __func__, view);
}

@end
