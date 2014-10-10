//
//  SMMessageThreadViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/2/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageThreadCellViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMMessageViewController.h"
#import "SMMessageListController.h"
#import "SMAppDelegate.h"

@interface SMMessageThreadViewController()
- (void)messageBodyFetched:(NSNotification *)notification;
- (void)updateMessageView:(uint32_t)uid threadId:(uint64_t)threadId;
- (void)arrangeCellSubviews;
@end

@implementation SMMessageThreadViewController {
	SMMessageThread *_currentMessageThread;
	NSMutableArray *_threadCellControllers;
	NSView *_contentView;
}

- (id)initWithFrame:(NSRect)frame {
	self = [super init];
	
	if (self) {
		_messageThreadView = [[NSScrollView alloc] initWithFrame:frame];
		
		[_messageThreadView setBorderType:NSNoBorder];
		[_messageThreadView setHasVerticalScroller:YES];
		[_messageThreadView setHasHorizontalScroller:NO];
		[_messageThreadView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		_threadCellControllers = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
	}
	
	return self;
}

- (SMMessageThread*)currentMessageThread {
	return _currentMessageThread;
}

- (void)setMessageThread:(SMMessageThread*)messageThread {
	NSAssert([messageThread messagesCount] > 0, @"no messages in message thread");
	
	if(_currentMessageThread == messageThread)
		return;
	
	_currentMessageThread = messageThread;
	
	[self arrangeCellSubviews];
}

- (void)arrangeCellSubviews {
	[_threadCellControllers removeAllObjects];
	
	_contentView = [[NSView alloc] initWithFrame:[_messageThreadView frame]];
	
	[_contentView setAutoresizesSubviews:NO];
	
	NSArray *messages = [_currentMessageThread messagesSortedByDate];
	if(messages.count > 1)
		[_contentView setAutoresizingMask:NSViewWidthSizable];
	else
		[_contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
	CGFloat viewHeight = 0;
	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessage *message = messages[i];
		
		//NSLog(@"%s: from '%@', subject '%@'", __FUNCTION__, [message from], [message subject]);
		
		SMMessageThreadCellViewController *messageThreadCellViewController = [[SMMessageThreadCellViewController alloc] init];
		
		if(messages.count > 1)
			[messageThreadCellViewController enableCollapse];
		
		[_threadCellControllers addObject:messageThreadCellViewController];
		
		SMMessageViewController *messageViewController = [messageThreadCellViewController messageViewController];
		
		NSAssert(messageViewController, @"message view controller not found");
		
		SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
		SMMessageListController *messageListController = [[appDelegate model] messageListController];
		
		NSString *htmlMessageBodyText = [ message htmlBodyRendering ];
		
		if(htmlMessageBodyText) {
			[message fetchInlineAttachments];
			
			[messageViewController setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[messageListController currentFolderName]];
		} else {
			NSLog(@"%s: no message body!", __FUNCTION__);
			
			[messageListController fetchMessageBodyUrgently:[message uid] threadId:[_currentMessageThread threadId]];
		}
		
		[messageViewController setMessageDetails:message];
		
		NSView *subview = [messageThreadCellViewController view];
		
		[_contentView addSubview:subview];
		
		if(i > 0) {
			const CGFloat spacing = 1;
			
			viewHeight += spacing;
		}
		
		viewHeight += messageThreadCellViewController.height;
	}
	
	[self setViewConstraints];
	
	if([_contentView frame].size.height < viewHeight)
		[_contentView setFrameSize:NSMakeSize([_contentView frame].size.width, viewHeight)];
	
	[_messageThreadView setDocumentView:_contentView];
}

- (void)setCellConstraints:(NSView*)cell height:(CGFloat)height {
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:0 multiplier:0 constant:height];

	constraint.priority = NSLayoutPriorityRequired;
	
	[cell addConstraint:constraint];
}

- (void)setViewConstraints {
	NSArray *subviews = [_contentView subviews];
	NSView *prevSubView = nil;
	
	if(subviews.count == 1)
	{
		NSView *subview = subviews[0];

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
	}
	else
	{
		for(NSInteger i = 0; i < subviews.count; i++) {
			NSView *subview = subviews[i];
			
			[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
			
			[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
			
			NSLayoutConstraint *topConstraint;
			
			if(i == 0) {
				topConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
			} else {
				const CGFloat spacing = 1;
				
				topConstraint = [NSLayoutConstraint constraintWithItem:prevSubView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:-spacing];
			}
			
			[topConstraint setPriority:NSLayoutPriorityDefaultHigh];
			[_contentView addConstraint:topConstraint];
			
			prevSubView = subview;
		}
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:prevSubView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
	}
}

- (void)buttonPressed:(id)sender {
	NSLog(@"%s: %@", __func__, sender);
	
	NSButton *button = sender;
	CGFloat h = [button frame].size.height;
	NSView *outerView = [button superview];
	NSView *cellView = nil;
	
	[button removeFromSuperview];
	
	for(int i = 0; i < 3; i++) {
		[outerView setFrameSize:NSMakeSize(outerView.frame.size.width, outerView.frame.size.height - h)];
		if(i < 2) {
			cellView = outerView;
			outerView = [outerView superview];
		}
	}

	[cellView removeConstraints:[cellView constraints]];
	
	[self setCellConstraints:cellView height:cellView.frame.size.height];
}

- (void)updateMessageView:(uint32_t)uid threadId:(uint64_t)threadId {
	if(_currentMessageThread == nil || _currentMessageThread.threadId != threadId)
		return;
	
	NSArray *messages = [_currentMessageThread messagesSortedByDate];
	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessage *message = messages[i];
		
		if(message.uid == uid) {
			NSString *htmlMessageBodyText = [ message htmlBodyRendering ];
			
			NSAssert(htmlMessageBodyText != nil, @"message has no body");
			
			[message fetchInlineAttachments];
			
			SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
			SMMessageListController *messageListController = [[appDelegate model] messageListController];
			
			[[_threadCellControllers[i] messageViewController] setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[messageListController currentFolderName]];
			
			[[_threadCellControllers[i] messageViewController] setMessageDetails:message];
			
			break;
		}
	}
}

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	[self updateMessageView:[[messageInfo objectForKey:@"UID"] unsignedIntValue] threadId:[[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue]];
}

/*
 - (void)tableViewSelectionDidChange:(NSNotification *)notification {
 //	NSInteger selectedRow = [ _messageListTableView selectedRow ];
	
	// TODO
	
 if(selectedRow >= 0) {
 SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
 SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:selectedRow];
 
 NSAssert(messageThread, @"messageThread == 0");
 
 NSString *htmlMessageBodyText = [ message htmlBodyRendering ];
 SMMessageListController *messageListController = [[appDelegate model] messageListController];
 
 if(htmlMessageBodyText) {
 if(_currentlyViewedMessage != message) {
 [[[appDelegate appController] messageViewController] setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[messageListController currentFolderName]];
 
 [message fetchInlineAttachments];
 
 _currentlyViewedMessage = message;
 
 MCOIMAPMessage *imapMessage = [message getImapMessage];
 NSLog(@"%s: fetched message uid %u, gmailMessageID %llu, gmailThreadID %llu", __func__, [imapMessage uid], [imapMessage gmailMessageID], [imapMessage gmailThreadID]);
 
 for(NSString *label in [imapMessage gmailLabels])
 NSLog(@"label: %@", label);
 
 }
 } else {
 NSLog(@"%s: no message body!", __FUNCTION__);
 
 [messageListController fetchMessageBodyUrgently:[message uid] threadId:[message gmailThreadId]];
 }
 
 [[[appDelegate appController] messageViewController] setMessageDetails:message];
 }
 }
 */

@end
