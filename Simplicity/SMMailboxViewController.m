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
#import "SMMailboxViewController.h"

@interface SMMailboxViewController()
- (SMFolder*)rootFolder;
@end

@implementation SMMailboxViewController {
	SMFolder *__weak _lastFolder;
}

- (void)updateFolderListView {
	NSInteger selectedRow = [ _folderListView selectedRow ];

	[ _folderListView reloadData ];

	[ _folderListView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO ];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	SMFolder *folder = (item != nil? (SMFolder *)item : [self rootFolder]);
	return [[folder subfolders] count];
}

- (NSArray *)_childrenForItem:(id)item {
	SMFolder *folder = (SMFolder *)item;
	return folder.subfolders;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	SMFolder *folder = (item != nil? (SMFolder *)item : [self rootFolder]);
	return folder.subfolders[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	SMFolder *folder = (item != nil? (SMFolder *)item : [self rootFolder]);
	return [folder.subfolders count] > 0;
}

/*
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	SMFolder *folder = (item != nil? (SMFolder *)item : [self rootFolder]);

	SMFolderCellView *result = [outlineView makeViewWithIdentifier:@"FolderCellView" owner:self];
	
	NSAssert(result != nil, @"cannot make folder text field");
	
	[result.textField setStringValue:[folder name]];
	
	return result;
}
*/

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item NS_AVAILABLE_MAC(10_7) {
	SMFolder *folder = (item != nil? (SMFolder *)item : [self rootFolder]);

//	NSLog(@"%s: folder '%@'", __func__, folder? [folder shortName] : @"<nil>");

	SMFolderCellView *result = [outlineView makeViewWithIdentifier:@"FolderCellView" owner:self];
	
	NSAssert(result != nil, @"cannot make folder text field");
	
	[result.textField setStringValue:[folder shortName]];
	
	return result;
}

/*
- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item NS_AVAILABLE_MAC(10_7) {
NSLog(@"trace: %s", __func__);
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row NS_AVAILABLE_MAC(10_7) {
 NSLog(@"trace: %s", __func__);
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row NS_AVAILABLE_MAC(10_7) {
 NSLog(@"trace: %s", __func__);
}
*/

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification {
	NSLog(@"trace: %s", __func__);
	
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [ _folderListView selectedRow ];
	SMFolder *folder = (SMFolder*)[_folderListView itemAtRow:selectedRow];
	
	if(folder == nil) {
		NSLog(@"%s: no row selected'", __func__);
		return;
	}
	
	if(folder == _lastFolder) {
		//NSLog(@"%s: selected folder didn't change", __func__);
		return;
	}
	
	NSAssert(folder, @"no folder selected"); // TODO: FIX!!!

	NSLog(@"%s: selected row %lu, folder short name '%@', full name '%@'", __func__, selectedRow, [folder shortName], [folder fullName]);
	
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMSimplicityContainer *model = [appDelegate model];

	[[model messageListController] changeFolder:[folder fullName]];
	
	_lastFolder = folder;
	
	[[[appDelegate appController] searchResultsListViewController] clearSelection];
}

- (SMFolder*)rootFolder {
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];
	
	return [mailbox root];
}

- (void)clearSelection {
	[_folderListView deselectAll:self];

	_lastFolder = nil;
}

@end
