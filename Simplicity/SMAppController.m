//
//  SMAppController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMailboxViewController.h"
#import "SMMessageListViewController.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageThreadViewController.h"

@implementation SMAppController {
	NSButton *button1, *button2;
}

@synthesize mailboxViewController = _mailboxViewController;
@synthesize messageListViewController = _messageListViewController;
@synthesize messageThreadViewController = _messageThreadViewController;

- (void)awakeFromNib {
	NSLog(@"SMAppController: awakeFromNib: _messageListViewController %@", _messageListViewController);
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	appDelegate.appController = self;
	
	//

	_mailboxViewController = [ [ SMMailboxViewController alloc ] initWithNibName:@"SMMailboxViewController" bundle:nil ];

	NSAssert(_mailboxViewController, @"_mailboxViewController");
	
	NSView *mailboxView = [ _mailboxViewController view ];

	NSAssert(mailboxView, @"mailboxView");
	NSAssert(_mailboxView, @"_mailboxView");

	[ _mailboxView addSubview:mailboxView ];
	[ mailboxView setFrame:[ _mailboxView bounds ] ];
	
	//

	_messageListViewController = [ [ SMMessageListViewController alloc ] initWithNibName:@"SMMessageListViewController" bundle:nil ];
	
	NSAssert(_messageListViewController, @"_messageListViewController");
		
	NSView *messageListView = [ _messageListViewController view ];
	
	NSAssert(messageListView, @"messageListView");
	NSAssert(_messageListView, @"_messageListView");
	
	[ _messageListView addSubview:messageListView ];
	[ messageListView setFrame:[ _messageListView bounds ] ];
	
	//
	
	_messageThreadViewController = [ [ SMMessageThreadViewController alloc ] initWithFrame:[_messageThreadView bounds] ];
	
	NSAssert(_messageThreadViewController, @"_messageThreadViewController");
	
	NSView *messageThreadView = [ _messageThreadViewController messageThreadView ];
	
	NSAssert(messageThreadView, @"messageThreadView");
	NSAssert(_messageThreadView, @"_messageThreadView");
	
	[ _messageThreadView addSubview:messageThreadView ];
	[ messageThreadView setFrame:[ _messageThreadView bounds ] ];
}

- (void)setMessageListViewController:(SMMessageListViewController*)messageListViewController {
	_messageListViewController = messageListViewController;

	NSLog(@"SMAppController: _messageListViewController %@, _messageListViewController.view %@", _messageListViewController, [ _messageListViewController view ]);

	[ _messageListView addSubview:[ _messageListViewController view ] ];
	[ [ _messageListViewController view ] setFrame:[ _messageListView bounds ] ];
}

- (SMMessageListViewController*)messageListViewController {
	return _messageListViewController;
}

- (void)updateMessageListView {
	[ _messageListViewController updateMessageListView ];
}

- (void)updateMailboxFolderListView {
	[ _mailboxViewController updateFolderListView ];
}

@end
