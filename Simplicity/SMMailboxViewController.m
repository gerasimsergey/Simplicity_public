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
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];

	NSInteger selectedRow = [ _folderListView selectedRow ];
	
	if(selectedRow < 0 || selectedRow >= [mailbox folders].count) {
		NSLog(@"%s: selected row %ld is beyond folders list size %lu", __func__, selectedRow, mailbox.folders.count);
		return;
	}

	SMFolder *folder = mailbox.folders[selectedRow];

	NSAssert(folder, @"bad folder");
	
	if(folder == _lastFolder) {
		//NSLog(@"%s: selected folder didn't change", __func__);
		return;
	}
	
	NSLog(@"%s: selected row %lu, folder short name '%@', full name '%@'", __func__, selectedRow, folder.shortName, folder.fullName);
	
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
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return mailbox.folders.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];

	SMFolderCellView *result = [tableView makeViewWithIdentifier:@"FolderCellView" owner:self];
	
	NSAssert(result != nil, @"cannot make folder text field");
	NSAssert(row >= 0 && row < mailbox.folders.count, @"row %ld is beyond folders array size %lu", row, mailbox.folders.count);
	
	SMFolder *folder = mailbox.folders[row];
	[result.textField setStringValue:folder.fullName];

	NSAssert([result.imageView isKindOfClass:[SMColorCircle class]], @"bad type of folder cell image");;

	SMColorCircle *colorMark = (SMColorCircle *)result.imageView;
	colorMark.color = folder.color;
	
	return result;
}

@end
