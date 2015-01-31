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
	NSLog(@"Can Items at indexes : %@", indexes);
	return YES;
}

-(BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSLog(@"Write Items at indexes : %@", indexes);
	return YES;
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
	NSLog(@"Accept Drop");
	return YES;
}

-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
	NSLog(@"Validate Drop");
	return NSDragOperationMove;
}

@end
