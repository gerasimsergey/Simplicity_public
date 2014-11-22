//
//  SMSearchResultsListController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMSearchDescriptor.h"
#import "SMSearchResultsListController.h"

@implementation SMSearchResultsListController {
	NSUInteger _searchId;
	NSMutableDictionary *_searchResults;
	NSMutableArray *_searchResultsOrdered;
}

- (id)init {
	self = [super init];
	
	if(self != nil) {
		_searchResults = [[NSMutableDictionary alloc] init];
		_searchResultsOrdered = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (NSString*)startNewSearch:(NSString*)searchPattern {
	// TODO: introduce search results descriptor to avoid this funny folder name
	NSString *folder = [NSString stringWithFormat:@"//search_results//%lu", _searchId++];
	
	NSAssert(folder != nil, @"folder name couldn't be generated");
	NSAssert([_searchResults objectForKey:folder] == nil, @"duplicated generated folder name");
	
	SMSearchDescriptor *searchDescriptor = [[SMSearchDescriptor alloc] init:searchPattern localFolder:folder];
	
	[_searchResults setObject:searchDescriptor forKey:folder];
	[_searchResultsOrdered addObject:folder];
	
	return folder;
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
