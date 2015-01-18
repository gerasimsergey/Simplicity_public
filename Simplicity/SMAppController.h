//
//  SMAppController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class SMMailboxViewController;
@class SMSearchResultsListViewController;
@class SMMessageListViewController;
@class SMMessageViewController;
@class SMMessageThreadViewController;
@class SMInstrumentPanelViewController;

@interface SMAppController : NSObject <NSToolbarDelegate, NSSplitViewDelegate>

@property (weak, nonatomic) IBOutlet NSView *view;

@property (nonatomic) IBOutlet NSToolbar *toolbar;
@property (nonatomic) IBOutlet NSTextField *searchField;

@property SMMailboxViewController *mailboxViewController;
@property SMSearchResultsListViewController *searchResultsListViewController;
@property SMMessageListViewController *messageListViewController;
@property SMMessageThreadViewController *messageThreadViewController;
@property SMInstrumentPanelViewController *instrumentPanelViewController;

- (void)updateMailboxFolderListView;
- (void)toggleSearchResultsView;

@end
