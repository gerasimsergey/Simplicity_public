//
//  SMSearchResultsListViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMSimplicityContainer.h"
#import "SMSearchResultsListController.h"
#import "SMSearchResultsListViewController.h"

@implementation SMSearchResultsListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		NSTableView *view = [[NSTableView alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;

		NSTableColumn *column =[[NSTableColumn alloc]initWithIdentifier:@"1"];
		[column.headerCell setTitle:@"Search results"];
		
		[view addTableColumn:column];

		[view setDataSource:self];
		[view setDelegate:self];
		
		// finally, commit the main view
		
		[self setView:view];
	}
	
	return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	return [[[appDelegate model] searchResultsListController] searchResultsCount];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *viewId = @"SearchResultView";
	NSTextField *result = [tableView makeViewWithIdentifier:viewId owner:self];
 
	if(result == nil) {
		result = [[NSTextField alloc] init];
		result.identifier = viewId;
	}
 
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

	result.stringValue = [[[appDelegate model] searchResultsListController] searchPattern:row];
 
	return result;
 
}

- (void)reloadData {
	[((NSTableView*)[self view]) reloadData];
}

@end
