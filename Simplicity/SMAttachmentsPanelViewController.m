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

//	[pasteboard declareTypes:[NSArray arrayWithObject:NSURLPboardType] owner:nil];

	NSString *filePath = @"/Users/evgeny_baskakov/ReleaseNotes_NEXTGEN_10_6_DEV_HUMAX4K_20150201_1807.html";
	NSURL *fileURL = [NSURL URLWithString:filePath];
//	[fileURL writeToPasteboard:pasteboard];

/*
	[pasteboard clearContents];
	NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
	[item setString:filePath forType:NSPasteboardTypeString];
	[pasteboard writeObjects:[NSArray arrayWithObject:item]];
*/
	
//	[pasteboard setPropertyList:[NSArray arrayWithObject:filePath] forType:NSFilenamesPboardType];
/*
	NSMutableArray *urls = [NSMutableArray array];
	[urls addObject:filePath];
	
	[pasteboard clearContents];
	
	[pasteboard writeObjects:urls];
*/

	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType] owner:self];
//	[pasteboard addTypes:@[@"my_drag_type_id"] owner:self];

	[pasteboard setPropertyList:@[@"pdf"] forType:NSFilesPromisePboardType];
//	[fileURL writeToPasteboard:pasteboard];

	
	return YES;
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
	NSLog(@"%s", __func__);
	switch(context) {
		case NSDraggingContextOutsideApplication:
			return NSDragOperationCopy;
			
		case NSDraggingContextWithinApplication:
		default:
			// TODO?
			return NSDragOperationCopy;
	}
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger)index dropOperation:(NSCollectionViewDropOperation)dropOperation {
	NSLog(@"Accept Drop");
	return YES;
}

-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id<NSDraggingInfo>)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
	NSLog(@"%s", __func__);
	return NSDragOperationCopy;
}

- (NSArray *)collectionView:(NSCollectionView *)collectionView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropURL forDraggedItemsAtIndexes:(NSIndexSet *)indexes {
	NSLog(@"namesOfPromisedFilesDroppedAtDestination");
	return [NSArray arrayWithObject:@"my_file.txt"];
}

@end
