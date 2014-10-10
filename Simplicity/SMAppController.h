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
@class SMMessageListViewController;
@class SMMessageViewController;
@class SMMessageThreadViewController;

@interface SMAppController : NSObject

@property (weak, nonatomic) IBOutlet NSView *mailboxView;
@property (weak, nonatomic) IBOutlet NSView *messageListView;
@property (weak, nonatomic) IBOutlet NSView *messageThreadView;

@property SMMailboxViewController *mailboxViewController;
@property SMMessageListViewController *messageListViewController;
@property SMMessageThreadViewController *messageThreadViewController;

- (void)setMessageListViewController:(SMMessageListViewController*)messageListViewController;
- (void)updateMessageListView;
- (void)updateMailboxFolderListView;

@end
