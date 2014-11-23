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
#import "SMMessageListController.h"
#import "SMSearchResultsListViewController.h"
#import "SMSearchResultsListController.h"

@implementation SMSearchResultsListController {
	NSUInteger _searchId;
	NSMutableDictionary *_searchResults;
	NSMutableArray *_searchResultsOrdered;
	MCOIMAPSearchOperation *_currentSearchOp;
}

- (id)init {
	self = [super init];
	
	if(self != nil) {
		_searchResults = [[NSMutableDictionary alloc] init];
		_searchResultsOrdered = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)startNewSearch:(NSString*)searchString {
	NSLog(@"%s: searching for string '%@'", __func__, searchString);
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	MCOIMAPSession *session = [[appDelegate model] session];
	
	NSAssert(session, @"session is nil");
	
	// TODO: handle search in search results differently
	NSString *remoteFolder = [[[[appDelegate model] messageListController] currentLocalFolder] name];

	// TODO: introduce search results descriptor to avoid this funny folder name
	NSString *searchResultsLocalFolder = [NSString stringWithFormat:@"//search_results//%lu", _searchId++];
	
	NSAssert(searchResultsLocalFolder != nil, @"folder name couldn't be generated");
	NSAssert([_searchResults objectForKey:searchResultsLocalFolder] == nil, @"duplicated generated folder name");
	
	SMSearchDescriptor *searchDescriptor = [[SMSearchDescriptor alloc] init:searchString localFolder:searchResultsLocalFolder];
	
	[_searchResults setObject:searchDescriptor forKey:searchResultsLocalFolder];
	[_searchResultsOrdered addObject:searchResultsLocalFolder];

	[[[appDelegate appController] searchResultsListViewController] reloadData];
	
	[_currentSearchOp cancel];
	_currentSearchOp = [session searchOperationWithFolder:remoteFolder kind:MCOIMAPSearchKindContent searchString:searchString];
	
	[_currentSearchOp start:^(NSError *error, MCOIndexSet *searchResults) {
		if(error == nil) {
			if(searchResults.count > 0) {
				SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
				
				NSLog(@"%s: %u messages found in remote folder %@, loading to local folder %@", __func__, [searchResults count], remoteFolder, searchResultsLocalFolder);
				
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
	for(NSInteger i = 0; i < _searchResultsOrdered.count; i++) {
		if([_searchResultsOrdered[i] isEqualToString:searchResultsLocalFolder])
			return i;
	}
	
	return -1;
}

- (NSUInteger)searchResultsCount {
	return [_searchResults count];
}

- (NSString*)searchResultsLocalFolder:(NSUInteger)index {
	return _searchResultsOrdered[index];
}

- (NSString*)searchPattern:(NSUInteger)index {
	SMSearchDescriptor *searchDescriptor = [_searchResults objectForKey:[self searchResultsLocalFolder:index]];

	return searchDescriptor.searchPattern;
}

- (void)searchHasFailed:(NSString*)searchResultsLocalFolder {
	const NSInteger index = [self getSearchIndex:searchResultsLocalFolder];
	SMSearchDescriptor *searchDescriptor = [_searchResults objectForKey:[self searchResultsLocalFolder:index]];
	
	searchDescriptor.searchFailed = true;
}

- (Boolean)hasSearchFailed:(NSUInteger)index {
	SMSearchDescriptor *searchDescriptor = [_searchResults objectForKey:[self searchResultsLocalFolder:index]];
	
	return searchDescriptor.searchFailed;
}

- (void)removeSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsOrdered.count, @"index is out of bounds");

	[_searchResults removeObjectForKey:[_searchResultsOrdered objectAtIndex:index]];
	[_searchResultsOrdered removeObjectAtIndex:index];
}

- (void)reloadSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsOrdered.count, @"index is out of bounds");
	
	// TODO
}

- (void)stopSearch:(NSInteger)index {
	NSLog(@"%s: request for index %ld", __func__, index);

	NSAssert(index >= 0 && index < _searchResultsOrdered.count, @"index is out of bounds");

	// TODO
}

@end
