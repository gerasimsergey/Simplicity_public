//
//  SMSearchResultsListViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/7/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMSearchResultsListViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>

@property IBOutlet NSTableView *tableView;

- (void)reloadData;
- (void)clearSelection;
- (void)selectSearchResult:(NSString*)searchResultsLocalFolder;

- (void)removeSearch:(NSInteger)index;
- (void)reloadSearch:(NSInteger)index;
- (void)stopSearch:(NSInteger)index;

@end
