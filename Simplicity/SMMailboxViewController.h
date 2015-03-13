//
//  SMMailboxViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/21/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMMailbox;
@class SMFolder;

@interface SMMailboxViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTableView *folderListView;

@property (weak, readonly) SMFolder *currentFolder;

- (void)changeFolder:(NSString*)folderName;
- (void)updateFolderListView;
- (void)clearSelection;

- (NSMenu*)menuForRow:(NSInteger)row;

@end
