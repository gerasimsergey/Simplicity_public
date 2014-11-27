//
//  SMSearchResultsListController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMSearchDescriptor.h"
#import "SMLocalFolder.h"
#import "SMLocalFolderRegistry.h"
#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMSearchResultsListViewController.h"
#import "SMSearchResultsListController.h"

@implementation SMSearchResultsListController {
	NSUInteger _searchId;
	NSMutableDictionary *_searchResults;
	NSMutableArray *_searchResultsFolderNames;
	MCOIMAPSearchOperation *_currentSearchOp;
}

- (id)init {
	self = [super init];
	
	if(self != nil) {
		_searchResults = [[NSMutableDictionary alloc] init];
		_searchResultsFolderNames = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)startNewSearch:(NSString*)searchString exitingLocalFolder:(NSString*)existingLocalFolder {
	NSLog(@"%s: searching for string '%@'", __func__, searchString);
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	MCOIMAPSession *session = [[appDelegate model] session];
	
	NSAssert(session, @"session is nil");
	
	NSString *remoteFolder = nil;
	NSString *searchResultsLocalFolder = nil;
	SMSearchDescriptor *searchDescriptor = nil;
	
	if(existingLocalFolder == nil) {
		// TODO: handle search in search results differently
		remoteFolder = [[[[appDelegate model] messageListController] currentLocalFolder] name];

		// TODO: introduce search results descriptor to avoid this funny folder name
		searchResultsLocalFolder = [NSString stringWithFormat:@"//search_results//%lu", _searchId++];
		
		NSAssert(searchResultsLocalFolder != nil, @"folder name couldn't be generated");
		NSAssert([_searchResults objectForKey:searchResultsLocalFolder] == nil, @"duplicated generated folder name");
		
		if([[[appDelegate model] localFolderRegistry] getOrCreateLocalFolder:searchResultsLocalFolder syncWithRemoteFolder:NO] == nil) {
			NSAssert(false, @"could not create local folder for search results");
		}
		
		searchDescriptor = [[SMSearchDescriptor alloc] init:searchString localFolder:searchResultsLocalFolder remoteFolder:remoteFolder];
	} else {
		searchResultsLocalFolder = existingLocalFolder;
		searchDescriptor = [_searchResults objectForKey:existingLocalFolder];
		remoteFolder = [searchDescriptor remoteFolder];

		NSAssert(searchDescriptor != nil, @"no search descriptor found for exiting local folder");
		
		[searchDescriptor clearState];
	}
	
	[_searchResults setObject:searchDescriptor forKey:searchResultsLocalFolder];
	[_searchResultsFolderNames addObject:searchResultsLocalFolder];

	[[[appDelegate appController] searchResultsListViewController] reloadData];
	
	[_currentSearchOp cancel];
	_currentSearchOp = [session searchOperationWithFolder:remoteFolder kind:MCOIMAPSearchKindContent searchString:searchString];
	
	[_currentSearchOp start:^(NSError *error, MCOIndexSet *searchResults) {
		if(error == nil) {
			if(searchResults.count > 0) {
				NSLog(@"%s: %u messages found in remote folder %@, loading to local folder %@", __func__, [searchResults count], remoteFolder, searchResultsLocalFolder);
				
				searchDescriptor.messagesLoadingStarted = YES;
				
				[[[appDelegate model] messageListController] loadSearchResults:searchResults remoteFolderToSearch:remoteFolder searchResultsLocalFolder:searchResultsLocalFolder];
				
				[[[appDelegate appController] searchResultsListViewController] selectSearchResult:searchResultsLocalFolder];
			} else {
				NSLog(@"%s: nothing found", __func__);
				
				[[[appDelegate model] searchResultsListController] searchHasFailed:searchResultsLocalFolder];
			}
		} else {
			NSLog(@"%s: search in remote folder %@ failed, error %@", __func__, remoteFolder, error);
			
			[[[appDelegate model] searchResultsListController] searchHasFailed:searchResultsLocalFolder];
		}
		
		[[[appDelegate appController] searchResultsListViewController] reloadData];
	}];
	
	/*
	 NSArray *rangesOfString = [self rangesOfStringInDocument:searchString];
	 if ([rangesOfString count]) {
		if ([documentTextView respondsToSelector:@selector(setSelectedRanges:)]) {
	 // NSTextView can handle multiple selections in 10.4 and later.
	 [documentTextView setSelectedRanges: rangesOfString];
		} else {
	 // If we can't do multiple selection, just select the first range.
	 [documentTextView setSelectedRange: [[rangesOfString objectAtIndex:0] rangeValue]];
		}
	 }
	 */
}

- (NSInteger)getSearchIndex:(NSString*)searchResultsLocalFolder {
	for(NSInteger i = 0; i < _searchResultsFolderNames.count; i++) {
		if([_searchResultsFolderNames[i] isEqualToString:searchResultsLocalFolder])
			return i;
	}
	
	return -1;
}

- (NSUInteger)searchResultsCount {
	return [_searchResults count];
}

- (SMSearchDescriptor*)getSearchResults:(NSUInteger)index {
	return [_searchResults objectForKey:[_searchResultsFolderNames objectAtIndex:index]];
}

- (void)searchHasFailed:(NSString*)searchResultsLocalFolder {
	SMSearchDescriptor *searchDescriptor = [_searchResults objectForKey:searchResultsLocalFolder];
	searchDescriptor.searchFailed = true;
}

- (void)removeSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsFolderNames.count, @"index is out of bounds");

	[_searchResults removeObjectForKey:[_searchResultsFolderNames objectAtIndex:index]];
	[_searchResultsFolderNames removeObjectAtIndex:index];
}

- (void)reloadSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsFolderNames.count, @"index is out of bounds");
	
	SMSearchDescriptor *searchDescriptor = [self getSearchResults:index];
	NSAssert(searchDescriptor != nil, @"search descriptor not found");

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMLocalFolder *localFolder = [[[appDelegate model] localFolderRegistry] getLocalFolder:searchDescriptor.localFolder];
	
	[localFolder clear];

	Boolean preserveSelection = NO;
	[[[appDelegate appController] messageListViewController] reloadMessageList:preserveSelection];

	[self startNewSearch:searchDescriptor.searchPattern exitingLocalFolder:localFolder.name];
}

- (void)stopSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsFolderNames.count, @"index is out of bounds");

	// stop search op itself, if any
	[_currentSearchOp cancel];
	_currentSearchOp = nil;

	// stop message list loading, if anys
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMSearchDescriptor *searchDescriptor = [self getSearchResults:index];
	NSAssert(searchDescriptor != nil, @"search descriptor not found");

	SMLocalFolder *localFolder = [[[appDelegate model] localFolderRegistry] getLocalFolder:searchDescriptor.localFolder];
	[localFolder stopMessageHeadersLoading];
	
	searchDescriptor.searchStopped = true;

	// TODO: stop message bodies loading?
}

- (Boolean)searchStopped:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);
	
	NSAssert(index >= 0 && index < _searchResultsFolderNames.count, @"index is out of bounds");
	
	// stop message list loading, if anys
	SMSearchDescriptor *searchDescriptor = [self getSearchResults:index];
	
	return searchDescriptor.searchStopped;
}

@end
