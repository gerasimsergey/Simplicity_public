//
//  SMMailboxViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/21/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMailbox.h"
#import "SMFolder.h"
#import "SMFolderCellView.h"
#import "SMSimplicityContainer.h"
#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMSearchResultsListViewController.h"
#import "SMColorCircle.h"
#import "SMMailboxController.h"
#import "SMMailboxViewController.h"
#import "SMFolderColorController.h"

@implementation SMMailboxViewController {
	NSInteger _rowWithMenu;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		;
	}
	
	return self;
}

- (void)viewDidLoad {
	NSColor *mailboxViewBackground = [NSColor colorWithPatternImage:[NSImage imageNamed:@"background_repeat.png"]];
	
	_folderListView.backgroundColor = mailboxViewBackground;

	[_folderListView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[_folderListView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}

- (void)updateFolderListView {
	NSInteger selectedRow = [ _folderListView selectedRow ];

	[ _folderListView reloadData ];

	[ _folderListView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO ];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [_folderListView selectedRow];
	if(selectedRow < 0 || selectedRow >= [self totalFolderRowsCount])
		return;

	SMFolder *folder = [self selectedFolder:selectedRow];
	
	if(folder == nil || folder == _currentFolder)
		return;
	
	//NSLog(@"%s: selected row %lu, folder short name '%@', full name '%@'", __func__, selectedRow, folder.shortName, folder.fullName);
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMSimplicityContainer *model = [appDelegate model];

	[[[appDelegate appController] messageListViewController] stopProgressIndicators];

	[[model messageListController] changeFolder:folder.fullName];

	_currentFolder = folder;
	
	[[[appDelegate appController] searchResultsListViewController] clearSelection];
}

- (void)clearSelection {
	[_folderListView deselectAll:self];

	_currentFolder = nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self totalFolderRowsCount];
}

- (NSInteger)mainFoldersGroupOffset {
	return 0;
}

- (NSInteger)favoriteFoldersGroupOffset {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];

	return 1 + mailbox.mainFolders.count;
}

- (NSInteger)allFoldersGroupOffset {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return 1 + mailbox.mainFolders.count + 1 + mailbox.favoriteFolders.count;
}

- (NSInteger)totalFolderRowsCount {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return 1 + mailbox.mainFolders.count + 1 + mailbox.favoriteFolders.count + 1 + mailbox.folders.count;
}

- (SMFolder*)selectedFolder:(NSInteger)row {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	const NSInteger mainFoldersGroupOffset = [self mainFoldersGroupOffset];
	const NSInteger favoriteFoldersGroupOffset = [self favoriteFoldersGroupOffset];
	const NSInteger allFoldersGroupOffset = [self allFoldersGroupOffset];
	
	if(row > mainFoldersGroupOffset && row < favoriteFoldersGroupOffset)
		return mailbox.mainFolders[row - mainFoldersGroupOffset - 1];
	else if(row > favoriteFoldersGroupOffset && row < allFoldersGroupOffset)
		return mailbox.favoriteFolders[row - favoriteFoldersGroupOffset - 1];
	else if(row > allFoldersGroupOffset)
		return mailbox.folders[row - allFoldersGroupOffset - 1];
	else
		return nil;
}

- (NSImage*)mainFolderImage:(SMFolder*)folder {
	switch(folder.kind) {
		case SMFolderKindInbox:
			return [NSImage imageNamed:@"inbox-white.png"];
		case SMFolderKindImportant:
			return [NSImage imageNamed:@"important-white.png"];
		case SMFolderKindSent:
			return [NSImage imageNamed:@"sent-white.png"];
		case SMFolderKindSpam:
			return [NSImage imageNamed:@"spam-white.png"];
		case SMFolderKindOutbox:
			return [NSImage imageNamed:@"outbox-white.png"];
		case SMFolderKindStarred:
			return [NSImage imageNamed:@"star-white.png"];
		case SMFolderKindDrafts:
			return [NSImage imageNamed:@"drafts-white.png"];
		case SMFolderKindTrash:
			return [NSImage imageNamed:@"trash-white.png"];
		default:
			return nil;
	}
}

typedef enum {
	kMainFoldersGroupHeader,
	kFavoriteFoldersGroupHeader,
	kAllFoldersGroupHeader,
	kMainFoldersGroupItem,
	kFavoriteFoldersGroupItem,
	kAllFoldersGroupItem
} FolderListItemKind;

- (FolderListItemKind)getRowKind:(NSInteger)row {
	NSInteger totalRowCount = [self totalFolderRowsCount];
	NSAssert(row >= 0 && row < totalRowCount, @"row %ld is beyond folders array size %lu", row, totalRowCount);
	
	const NSInteger mainFoldersGroupOffset = [self mainFoldersGroupOffset];
	const NSInteger favoriteFoldersGroupOffset = [self favoriteFoldersGroupOffset];
	const NSInteger allFoldersGroupOffset = [self allFoldersGroupOffset];

	if(row == mainFoldersGroupOffset) {
		return kMainFoldersGroupHeader;
	} else if(row == favoriteFoldersGroupOffset) {
		return kFavoriteFoldersGroupHeader;
	} else if(row == allFoldersGroupOffset) {
		return kAllFoldersGroupHeader;
	} else if(row < favoriteFoldersGroupOffset) {
		return kMainFoldersGroupItem;
	} else if(row < allFoldersGroupOffset) {
		return kFavoriteFoldersGroupItem;
	} else {
		return kAllFoldersGroupItem;
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSInteger totalRowCount = [self totalFolderRowsCount];
	NSAssert(row >= 0 && row < totalRowCount, @"row %ld is beyond folders array size %lu", row, totalRowCount);

	const NSInteger mainFoldersGroupOffset = [self mainFoldersGroupOffset];
	const NSInteger favoriteFoldersGroupOffset = [self favoriteFoldersGroupOffset];
	const NSInteger allFoldersGroupOffset = [self allFoldersGroupOffset];

	NSTableCellView *result = nil;

	FolderListItemKind itemKind = [self getRowKind:row];
	switch(itemKind) {
		case kMainFoldersGroupItem: {
			result = [tableView makeViewWithIdentifier:@"MainFolderCellView" owner:self];
			
			SMFolder *folder = [self selectedFolder:row];
			NSAssert(folder != nil, @"bad selected folder");
			
			[result.textField setStringValue:folder.displayName];
			[result.imageView setImage:[self mainFolderImage:folder]];
			
			break;
		}
			
		case kFavoriteFoldersGroupItem:
		case kAllFoldersGroupItem: {
			result = [tableView makeViewWithIdentifier:@"FolderCellView" owner:self];
			
			SMFolder *folder = [self selectedFolder:row];
			NSAssert(folder != nil, @"bad selected folder");
			
			[result.textField setStringValue:folder.displayName];
			
			NSAssert([result.imageView isKindOfClass:[SMColorCircle class]], @"bad type of folder cell image");;
			
			SMColorCircle *colorMark = (SMColorCircle *)result.imageView;
			
			SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
			SMAppController *appController = [appDelegate appController];
			
			colorMark.color = [[appController folderColorController] colorForFolder:folder.fullName];
			
			break;
		}
			
		default: {
			result = [tableView makeViewWithIdentifier:@"FolderGroupCellView" owner:self];
			
			const NSUInteger fontSize = 12;
			[result.textField setFont:[NSFont boldSystemFontOfSize:fontSize]];
			
			if(row == mainFoldersGroupOffset) {
				[result.textField setStringValue:@"Main Folders"];
			} else if(row == favoriteFoldersGroupOffset) {
				[result.textField setStringValue:@"Favorite Folders"];
			} else if(row == allFoldersGroupOffset) {
				[result.textField setStringValue:@"All Folders"];
			}
		}
	}
	
	NSAssert(result != nil, @"cannot make folder cell view");

	return result;
}

#pragma mark Messages drag and drop support

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
	// do not permit dragging folders

	return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// permit drop only at folders, not between them

	if(op == NSTableViewDropOn) {
		SMFolder *folder = [self selectedFolder:row];

		// TODO: set the current mailbox folder at the app startup

		if(folder != nil && folder != _currentFolder)
			return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)op
{
	SMFolder *targetFolder = [self selectedFolder:row];

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[[appDelegate appController] messageListViewController] moveSelectedMessageThreadsToFolder:targetFolder.fullName];

	return YES;
}

#pragma mark Context menu creation

- (NSMenu*)menuForRow:(NSInteger)row {
	if(row < 0 || row >= _folderListView.numberOfRows)
		return nil;

	// TODO: highlight the clicked row

	_rowWithMenu = row;

	NSMenu *menu = nil;

	FolderListItemKind itemKind = [self getRowKind:row];
	switch(itemKind) {
		case kMainFoldersGroupItem: {
			break;
		}
	
		case kFavoriteFoldersGroupItem: {
			menu = [[NSMenu alloc] init];
			
			[menu insertItemWithTitle:@"Delete label" action:@selector(deleteLabel) keyEquivalent:@"" atIndex:0];
			[menu insertItemWithTitle:@"Remove label from favorites" action:@selector(removeLabelFromFavorites) keyEquivalent:@"" atIndex:1];

			break;
		}

		case kAllFoldersGroupItem: {
			menu = [[NSMenu alloc] init];

			[menu insertItemWithTitle:@"New label" action:@selector(newLabel) keyEquivalent:@"" atIndex:0];
			[menu insertItemWithTitle:@"Delete label" action:@selector(deleteLabel) keyEquivalent:@"" atIndex:1];
			[menu insertItemWithTitle:@"Make label favorite" action:@selector(makeLabelFavorite) keyEquivalent:@"" atIndex:2];

			break;
		}

		default: {
			break;
		}
	}
	
	return menu;
}

- (void)newLabel {
	NSAssert(_rowWithMenu >= 0 && _rowWithMenu < _folderListView.numberOfRows, @"bad _rowWithMenu %ld", _rowWithMenu);

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMAppController *appController = [appDelegate appController];

	SMFolder *folder = [self selectedFolder:_rowWithMenu];
	NSAssert(folder != nil, @"bad selected folder");

	[appController showNewLabelSheet:folder.fullName];
}

- (void)deleteLabel {
	NSAssert(_rowWithMenu >= 0 && _rowWithMenu < _folderListView.numberOfRows, @"bad _rowWithMenu %ld", _rowWithMenu);
	
	NSLog(@"%s", __func__);
}

- (void)makeLabelFavorite {
	NSAssert(_rowWithMenu >= 0 && _rowWithMenu < _folderListView.numberOfRows, @"bad _rowWithMenu %ld", _rowWithMenu);

	SMFolder *folder = [self selectedFolder:_rowWithMenu];
	NSAssert(folder != nil, @"bad selected folder");

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];

	[[[appDelegate model] mailbox] addFavoriteFolderWithName:folder.fullName];
	[[[appDelegate appController] mailboxViewController] updateFolderListView];
}

- (void)removeLabelFromFavorites {
	NSAssert(_rowWithMenu >= 0 && _rowWithMenu < _folderListView.numberOfRows, @"bad _rowWithMenu %ld", _rowWithMenu);

	SMFolder *folder = [self selectedFolder:_rowWithMenu];
	NSAssert(folder != nil, @"bad selected folder");

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];

	[[[appDelegate model] mailbox] removeFavoriteFolderWithName:folder.fullName];
	[[[appDelegate appController] mailboxViewController] updateFolderListView];
}

@end
