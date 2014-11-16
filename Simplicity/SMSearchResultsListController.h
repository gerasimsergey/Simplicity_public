//
//  SMSearchResultsListController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMSearchResultsListController : NSObject

// TODO: introduce search pattern descriptor and search results descriptors

- (NSString*)startNewSearch:(NSString*)searchPattern;
- (void)deleteSearch:(NSString*)searchResultsLocalFolder;
- (NSInteger)getSearchIndex:(NSString*)searchResultsLocalFolder;
- (NSUInteger)searchResultsCount;
- (NSString*)searchResultsLocalFolder:(NSUInteger)index;
- (NSString*)searchPattern:(NSUInteger)index;
- (void)searchHasFailed:(NSString*)searchResultsLocalFolder;
- (Boolean)hasSearchFailed:(NSUInteger)index;

@end
