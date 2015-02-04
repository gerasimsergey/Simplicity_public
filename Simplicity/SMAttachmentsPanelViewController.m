//
//  SMAttachmentsPanelViewContoller.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/23/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsPanelViewController.h"

@implementation SMAttachmentsPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_attachmentItems = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {
	NSLog(@"%s: indexes %@", __func__, indexes);

	return YES;
}

-(BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSLog(@"%s: indexes %@", __func__, indexes);

	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType] owner:self];
	[pasteboard setPropertyList:@[@"cpp"] forType:NSFilesPromisePboardType];
	
	return YES;
}

 - (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
	switch(context) {
		case NSDraggingContextOutsideApplication:
			return NSDragOperationCopy;
			
		case NSDraggingContextWithinApplication:
			return NSDragOperationNone; // TODO: composing message with attachments
			
		default:
			return NSDragOperationNone;
	}
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
	NSLog(@"%s", __func__);

	return NO;
}

-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
	// do not recognize any drop to itself
	// TODO: may need to add logic for messages being composed
	return NSDragOperationNone;
}

- (NSArray *)collectionView:(NSCollectionView *)collectionView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropURL forDraggedItemsAtIndexes:(NSIndexSet *)indexes {
	NSLog(@"%s: indexes %@, drop url %@", __func__, indexes, dropURL);

	NSData *data = [NSData dataWithBytes:"abc" length:3];
	NSError *writeError = nil;
	if(![data writeToURL:[NSURL URLWithString:@"data.txt" relativeToURL:dropURL] options:NSDataWritingAtomic error:&writeError]) {
		NSLog(@"%s: Could not write file: %@", __func__, writeError);
		return [NSArray array];
	}

	return [NSArray arrayWithObject:@"my_file.txt"];
}

@end
