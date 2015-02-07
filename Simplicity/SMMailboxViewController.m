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
#import "SMSearchResultsListViewController.h"
#import "SMColorCircle.h"
#import "SMMailboxViewController.h"

@implementation SMMailboxViewController {
	SMFolder *__weak _lastFolder;
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
	
	if(folder == nil || folder == _lastFolder)
		return;
	
	NSLog(@"%s: selected row %lu, folder short name '%@', full name '%@'", __func__, selectedRow, folder.shortName, folder.fullName);
	
	SMAppDelegate *appDelegate =  [[NSApplication sharedApplication] delegate];
	SMSimplicityContainer *model = [appDelegate model];

	[[model messageListController] changeFolder:folder.fullName];
	
	_lastFolder = folder;
	
	[[[appDelegate appController] searchResultsListViewController] clearSelection];
}

- (void)clearSelection {
	[_folderListView deselectAll:self];

	_lastFolder = nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self totalFolderRowsCount];
}

- (NSInteger)mainFoldersGroupOffset {
	return 0;
}

- (NSInteger)favoriteFoldersGroupOffset {
	SMAppDelegate *appDelegate =  [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];

	return 1 + mailbox.mainFolders.count;
}

- (NSInteger)allFoldersGroupOffset {
	SMAppDelegate *appDelegate =  [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return 1 + mailbox.mainFolders.count + 1 + mailbox.favoriteFolders.count;
}

- (NSInteger)totalFolderRowsCount {
	SMAppDelegate *appDelegate =  [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return 1 + mailbox.mainFolders.count + 1 + mailbox.favoriteFolders.count + 1 + mailbox.folders.count;
}

- (SMFolder*)selectedFolder:(NSInteger)row {
	SMAppDelegate *appDelegate =  [[NSApplication sharedApplication] delegate];
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSInteger totalRowCount = [self totalFolderRowsCount];
	NSAssert(row >= 0 && row < totalRowCount, @"row %ld is beyond folders array size %lu", row, totalRowCount);

	const NSInteger mainFoldersGroupOffset = [self mainFoldersGroupOffset];
	const NSInteger favoriteFoldersGroupOffset = [self favoriteFoldersGroupOffset];
	const NSInteger allFoldersGroupOffset = [self allFoldersGroupOffset];

	NSTableCellView *result = nil;

	if(row > mainFoldersGroupOffset && row < favoriteFoldersGroupOffset) {
		result = [tableView makeViewWithIdentifier:@"MainFolderCellView" owner:self];
		
		SMFolder *folder = [self selectedFolder:row];
		NSAssert(folder != nil, @"bad selected folder");
		
		[result.textField setStringValue:folder.displayName];
		[result.imageView setImage:[self mainFolderImage:folder]];
	} else if(row != mainFoldersGroupOffset && row != favoriteFoldersGroupOffset && row != allFoldersGroupOffset) {
		result = [tableView makeViewWithIdentifier:@"FolderCellView" owner:self];
		
		SMFolder *folder = [self selectedFolder:row];
		NSAssert(folder != nil, @"bad selected folder");
		
		[result.textField setStringValue:folder.displayName];
		
		NSAssert([result.imageView isKindOfClass:[SMColorCircle class]], @"bad type of folder cell image");;

		SMColorCircle *colorMark = (SMColorCircle *)result.imageView;
		colorMark.color = folder.color;
	} else {
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
	
	NSAssert(result != nil, @"cannot make folder cell view");

	return result;
}

@end
