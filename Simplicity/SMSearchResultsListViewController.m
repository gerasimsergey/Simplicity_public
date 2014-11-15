//
//  SMSearchResultsListViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMSimplicityContainer.h"
#import "SMMessageListController.h"
#import "SMSearchResultsListController.h"
#import "SMMailboxViewController.h"
#import "SMLocalFolder.h"
#import "SMSearchResultsListCellView.h"
#import "SMSearchResultsListViewController.h"

@implementation SMSearchResultsListViewController {
	NSTableView *_tableView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_tableView = [[NSTableView alloc] init];
		_tableView.translatesAutoresizingMaskIntoConstraints = NO;

		NSTableColumn *column =[[NSTableColumn alloc]initWithIdentifier:@"1"];
		[column.headerCell setTitle:@"Search results"];
		
		[_tableView addTableColumn:column];

		[_tableView setDataSource:self];
		[_tableView setDelegate:self];
		
		// finally, commit the main view
		
		[self setView:_tableView];

		// set async event handler
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageHeadersFetched:) name:@"MessageHeadersFetched" object:nil];
	}
	
	return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	return [[[appDelegate model] searchResultsListController] searchResultsCount];
}

- (SMSearchResultsListCellView*)getSearchResultCell:(NSTableView *)tableView row:(NSInteger)row {
	NSString *viewId = @"SearchResultsCell";
	SMSearchResultsListCellView *result = [tableView makeViewWithIdentifier:viewId owner:self];
 
	if(result == nil) {
		NSArray *topLevelObjects = [[NSArray alloc] init];
		Boolean loadResult = [[NSBundle mainBundle] loadNibNamed:@"SMSearchResultsListCellView" owner:self topLevelObjects:&topLevelObjects];
		
		NSAssert(loadResult, @"Cannot load search results list cell");
		
		// TODO: looks stupid, find out a better way
		for(id object in topLevelObjects) {
			if([object isKindOfClass:[SMSearchResultsListCellView class]]) {
				result = object;
				break;
			}
		}
		
		NSAssert(result != nil, @"bad top objects");
		
		result.identifier = viewId;
	}
	
	return result;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	SMSearchResultsListCellView *result = [self getSearchResultCell:tableView row:row];
	NSAssert(result != nil, @"bad cell found");

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	
	NSString *searchLocalFolderName = [[[appDelegate model] searchResultsListController] searchResultsLocalFolder:row];
	NSAssert(searchLocalFolderName != nil, @"bad search folder name");
	
	SMLocalFolder *searchFolder = [[[appDelegate model] messageListController] getLocalFolder:searchLocalFolderName];

	// search folder may not exist yet because the search is just started
	// and there is no any search results... that is, the folder is not created
	if(searchFolder == nil) {
		// in this case the found messages aren't being loaded yet
		// so we can't show any percentage
		[result.progressIndicator setIndeterminate:YES];
		[result.progressIndicator startAnimation:self];
	} else if([searchFolder isStillUpdating]) {
		if([result.progressIndicator isIndeterminate])
			[result.progressIndicator setIndeterminate:NO];
		
		if(searchFolder.messageHeadersFetched == searchFolder.totalMessagesCount) {
			[result.progressIndicator stopAnimation:self];
		} else {
			double loadRatio = (searchFolder.messageHeadersFetched * 100) / (double)searchFolder.totalMessagesCount;
			[result.progressIndicator setDoubleValue:loadRatio];
		}
	}

//	[result.progressIndicator setNeedsDisplay:YES];

	result.textField.stringValue = [[[appDelegate model] searchResultsListController] searchPattern:row];

	return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	SMSearchResultsListCellView *result = [self getSearchResultCell:tableView row:row];
	NSAssert(result != nil, @"bad cell found");

	return result.frame.size.height;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [_tableView selectedRow];
	
	if(selectedRow >= 0) {
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMSearchResultsListController *searchResultsListController = [[appDelegate model] searchResultsListController];
		
		if(selectedRow < searchResultsListController.searchResultsCount) {
			[[[appDelegate model] messageListController] changeFolder:[searchResultsListController searchResultsLocalFolder:selectedRow]];

			[[[appDelegate appController] mailboxViewController] clearSelection];
		}
	}
}

- (void)reloadData {
	[_tableView reloadData];
}

- (void)clearSelection {
	[_tableView deselectAll:self];
}

- (void)messageHeadersFetched:(NSNotification *)notification {
	NSString *localFolder = [[notification userInfo] objectForKey:@"LocalFolderName"];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	NSInteger index = [[[appDelegate model] searchResultsListController] getSearchIndex:localFolder];

	if(index >= 0) {
		[_tableView reloadData];
	}
}

@end
