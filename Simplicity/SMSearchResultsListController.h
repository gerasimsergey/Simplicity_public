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
- (NSInteger)getSearchIndex:(NSString*)searchResultsLocalFolder;
- (NSUInteger)searchResultsCount;
- (NSString*)searchResultsLocalFolder:(NSUInteger)index;
- (NSString*)searchPattern:(NSUInteger)index;
- (void)searchHasFailed:(NSString*)searchResultsLocalFolder;
- (Boolean)hasSearchFailed:(NSUInteger)index;

- (void)removeSearch:(NSInteger)index;
- (void)reloadSearch:(NSInteger)index;
- (void)stopSearch:(NSInteger)index;

@end
