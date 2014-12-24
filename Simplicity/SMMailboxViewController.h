//
//  SMMailboxViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/21/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMMailbox;

@interface SMMailboxViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *folderListView;

- (void)updateFolderListView;
- (void)clearSelection;

@end
