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
	
	//

	_messageListViewController = [ [ SMMessageListViewController alloc ] initWithNibName:@"SMMessageListViewController" bundle:nil ];
	
	NSAssert(_messageListViewController, @"_messageListViewController");
		
	NSView *messageListView = [ _messageListViewController view ];

	NSAssert(messageListView, @"messageListView");
	
	//	[messageListView setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	//
	
	_messageThreadViewController = [ [ SMMessageThreadViewController alloc ] initWithNibName:nil bundle:nil ];
	
	NSAssert(_messageThreadViewController, @"_messageThreadViewController");
	
	NSView *messageThreadView = [ _messageThreadViewController messageThreadView ];
	
	NSAssert(messageThreadView, @"messageThreadView");

	[messageThreadView setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];

	//
	
	NSSplitView *splitView = [[NSSplitView alloc] init];
	splitView.translatesAutoresizingMaskIntoConstraints = NO;

	[splitView setVertical:YES];
	[splitView setDividerStyle:NSSplitViewDividerStyleThin];
	
	[splitView addSubview:mailboxView];
	[splitView addSubview:messageListView];
	[splitView addSubview:messageThreadView];
	
	[splitView adjustSubviews];

	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-1 forSubviewAtIndex:0];
	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-2 forSubviewAtIndex:1];
	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-3 forSubviewAtIndex:2];

	[_view addSubview:splitView];
	
	// 
	
	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
	
	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
	
	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];

	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)updateMessageListView {
	[ _messageListViewController updateMessageListView ];
}

- (void)updateMailboxFolderListView {
	[ _mailboxViewController updateFolderListView ];
}

@end
