//
//  SMAttachmentsPanelItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentItem.h"
#import "SMAttachmentsPanelItemViewController.h"

@implementation SMAttachmentsPanelItemViewController {
	NSTrackingArea *_trackingArea;
	Boolean _hasMouseOver;
}

- (NSColor*)selectedColor {
	return [NSColor selectedControlColor];
}

- (NSColor*)unselectedColor {
	return [NSColor windowBackgroundColor];
}

- (NSColor*)selectedColorWithMouseOver {
	return [[NSColor grayColor] blendedColorWithFraction:0.5 ofColor:[self selectedColor]];
}

- (NSColor*)unselectedWithMouseOverColor {
	return [NSColor grayColor];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		// nothing yet
	}
	
	return self;
}

- (void)viewDidLoad {
	_trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:(NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited) owner:self userInfo:nil];
	
	[_box addTrackingArea:_trackingArea];
}

- (void)setSelected:(BOOL)flag {
	[super setSelected:flag];
 
	NSAssert(_box != nil, @"no box set");

	NSColor *fillColor = flag? (_hasMouseOver? [self selectedColorWithMouseOver] : [self selectedColor]) : (_hasMouseOver? [self unselectedWithMouseOverColor] : [self unselectedColor]);
 
	[_box setFillColor:fillColor];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSColor *fillColor = [self isSelected]? [self selectedColorWithMouseOver] : [self unselectedWithMouseOverColor];
 
	[_box setFillColor:fillColor];
	
	_hasMouseOver = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSColor *fillColor = [self isSelected]? [self selectedColor] : [self unselectedColor];
 
	[_box setFillColor:fillColor];
	
	_hasMouseOver = NO;
}

-(void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];

	if([theEvent clickCount] == 2) {
		NSLog(@"%s: double click", __func__);
		//[NSApp sendAction:@selector(collectionItemViewDoubleClick:) to:nil from:[self object]];
		
		SMAttachmentItem *attachmentItem = [self representedObject];

		NSLog(@"%s: attachment item %@", __func__, attachmentItem.fileName);

		NSString *filePath = [NSString pathWithComponents:@[@"/tmp", attachmentItem.fileName]];

		// TODO: write to the message attachments folder
		// TODO: write only if not written yet (compare checksum?)
		// TODO: do it asynchronously
		NSError *writeError = nil;
		if(![attachmentItem.fileData writeToFile:filePath options:NSDataWritingAtomic error:&writeError]) {
			NSLog(@"%s: Could not write file %@: %@", __func__, filePath, writeError);
			return; // TODO: error popup?
		}
		
		NSLog(@"%s: File written: %@", __func__, filePath);

		[[NSWorkspace sharedWorkspace] openFile:filePath];
	}
}

@end
