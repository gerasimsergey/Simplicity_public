//
//  SMAttachmentsPanelView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/31/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsPanelView.h"

@implementation SMAttachmentsPanelView

- (id)init {
	self = [super init];
	
	if(self) {
		NSLog(@"%s", __func__);
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	[self registerForDraggedTypes:@[@"my_drag_type_id"]];

	[super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray
						fromRect:(NSRect)aRect
						  source:(id)sourceObject
					   slideBack:(BOOL)slideBack
						   event:(NSEvent *)theEvent
{
	NSLog(@"%s", __func__);
	return YES;
}

- (void)setDraggingSourceOperationMask:(NSDragOperation)dragOperationMask forLocal:(BOOL)localDestination {
	NSLog(@"%s", __func__);
}

- (NSImage *)draggingImageForItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event offset:(NSPointPointer)dragImageOffset {
	NSLog(@"%s", __func__);
	return nil;
}

@end
