//
//  SMMessageListViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMMessageListViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>

@property IBOutlet NSButton *loadMoreMessagesButton;

- (IBAction)loadMoreMessages:(id)sender;

- (void)reloadMessageList:(Boolean)preserveSelection;

@end
