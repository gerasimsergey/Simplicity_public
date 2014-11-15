//
//  SMSearchResultsListController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

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
	
	[_searchResults setObject:searchPattern forKey:folder];
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

- (void)deleteSearch:(NSString*)searchResultsLocalFolder {
	NSAssert([_searchResults objectForKey:searchResultsLocalFolder] != nil, @"no such search results folder");

	[_searchResults removeObjectForKey:searchResultsLocalFolder];

	const NSInteger index = [self getSearchIndex:searchResultsLocalFolder];
	
	if(index >= 0)
		[_searchResultsOrdered removeObjectAtIndex:index];
}

- (NSUInteger)searchResultsCount {
	return [_searchResults count];
}

- (NSString*)searchResultsLocalFolder:(NSUInteger)index {
	return _searchResultsOrdered[index];
}

- (NSString*)searchPattern:(NSUInteger)index {
	return [_searchResults objectForKey:[self searchResultsLocalFolder:index]];
}


@end
