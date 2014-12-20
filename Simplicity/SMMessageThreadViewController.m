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
@end

@implementation SMMessageThreadViewController {
	NSMutableArray *_threadCellControllers;
	NSMutableArray *_messages;
	NSView *_contentView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_messageThreadView = [[NSScrollView alloc] init];
		
		[_messageThreadView setBorderType:NSNoBorder];
		[_messageThreadView setHasVerticalScroller:YES];
		[_messageThreadView setHasHorizontalScroller:NO];
		[_messageThreadView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		_threadCellControllers = [NSMutableArray new];
		_messages = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
	}
	
	return self;
}

- (SMMessageThreadCellViewController*)createMessageThreadCell:(SMMessage*)message {
	SMMessageThreadCellViewController *messageThreadCellViewController = [[SMMessageThreadCellViewController alloc] init];
	
	[_threadCellControllers addObject:messageThreadCellViewController];
	
	SMMessageViewController *messageViewController = [messageThreadCellViewController messageViewController];
	
	NSAssert(messageViewController, @"message view controller not found");
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	
	NSString *htmlMessageBodyText = [ message htmlBodyRendering ];
	
	if(htmlMessageBodyText) {
		[message fetchInlineAttachments];
		
		[messageThreadCellViewController setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[message remoteFolder]];
	} else {
		[messageListController fetchMessageBodyUrgently:[message uid] remoteFolder:[message remoteFolder] threadId:[_currentMessageThread threadId]];
	}
	
	[messageViewController setMessageDetails:message];

	return messageThreadCellViewController;
}

- (void)setMessageThread:(SMMessageThread*)messageThread {
	NSAssert([messageThread messagesCount] > 0, @"no messages in message thread");
	
	if(_currentMessageThread == messageThread)
		return;
	
	_currentMessageThread = messageThread;
	
	[_threadCellControllers removeAllObjects];
	[_messages removeAllObjects];
	
	_contentView = [[NSView alloc] initWithFrame:[_messageThreadView frame]];
	_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	
	NSArray *messages = [_currentMessageThread messagesSortedByDate];

	[_messages addObjectsFromArray:messages];

	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessageThreadCellViewController *messageThreadCellViewController = [self createMessageThreadCell:messages[i]];
		
		if(messages.count > 1)
			[messageThreadCellViewController enableCollapse];
		
		[_contentView addSubview:[messageThreadCellViewController view]];
	}
	
	[_messageThreadView setDocumentView:_contentView];

	[self setViewConstraints];
}

- (void)updateMessageThread {
	if(_currentMessageThread == nil)
		return;

	NSAssert(_messages != nil, @"no messages in the current thread");

	NSArray *newMessages = [_currentMessageThread messagesSortedByDate];
	
	// check whether messages did not change
	if(newMessages.count == _messages.count) {
		Boolean equal = YES;

		for(NSInteger i = 0; i < _messages.count; i++) {
			if(newMessages[i] != _messages[i]) {
				equal = NO;
				break;
			}
		}
		
		if(equal)
			return;
	}
	
	NSLog(@"%s: message thread id %llu has been updated (old message count %lu, new %ld)", __func__, _currentMessageThread.threadId, (unsigned long)_messages.count, (long)_currentMessageThread.messagesCount);
	
	// remove old (vanished) messages
	for(NSInteger i = _messages.count; i > 0; i--) {
		NSInteger index = i-1;
		SMMessage *message = _messages[index];
		
		// TODO: use the sorting info for search
		if(![newMessages containsObject:message]) {
			SMMessageViewController *messageViewController = [_threadCellControllers[index] messageViewController];

			[[messageViewController view] removeFromSuperview];

			[_threadCellControllers removeObjectAtIndex:index];
			[_messages removeObjectAtIndex:index];
		}
	}

	NSMutableArray *updatedMessages = [NSMutableArray new];

	// add new messages
	for(NSInteger i = 0, j = 0; i < newMessages.count; i++) {
		SMMessage *newMessage = newMessages[i];
		
		if(j >= _messages.count || _messages[j] != newMessage) {
			[updatedMessages addObject:newMessage];
			
			SMMessageThreadCellViewController *messageThreadCellViewController = [self createMessageThreadCell:newMessage];
			
			if(updatedMessages.count > 1)
				[messageThreadCellViewController enableCollapse];
			
			[_contentView addSubview:[messageThreadCellViewController view]];
		} else {
			[updatedMessages addObject:_messages[j++]];
		}
	}

	// populate the updated view
	_messages = updatedMessages;

	[_contentView removeConstraints:[_contentView constraints]];
	[self setViewConstraints];
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
		
		NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:prevSubView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];

		// use low priority here for now because we want to leave blank space
		// between the message cell at the bottom and the thread view itself
		// otherwise it will cause the thread view to shrink height
		[bottomConstraint setPriority:NSLayoutPriorityDefaultLow];

		[_contentView addConstraint:bottomConstraint];
	}

	[[_contentView superview] addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:[_contentView superview] attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
	
	[[_contentView superview] addConstraint:[NSLayoutConstraint constraintWithItem:[_contentView superview] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
	
	[[_contentView superview] addConstraint:[NSLayoutConstraint constraintWithItem:[_contentView superview] attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
}

- (void)updateMessageView:(uint32_t)uid threadId:(uint64_t)threadId {
	if(_currentMessageThread == nil || _currentMessageThread.threadId != threadId)
		return;
	
	NSArray *messages = [_currentMessageThread messagesSortedByDate];
	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessage *message = messages[i];
		
		// TODO: optimize search
		if(message.uid == uid) {
			NSString *htmlMessageBodyText = [ message htmlBodyRendering ];
			
			NSAssert(htmlMessageBodyText != nil, @"message has no body");
			
			[message fetchInlineAttachments];
			
			NSAssert(i < _threadCellControllers.count, @"inconsistent thread cell controllers array");
			
			SMMessageThreadCellViewController *cellController = _threadCellControllers[i];
			
			[cellController setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[message remoteFolder]];
			
			[[cellController messageViewController] setMessageDetails:message];
			
			break;
		}
	}
}

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	[self updateMessageView:[[messageInfo objectForKey:@"UID"] unsignedIntValue] threadId:[[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue]];
}

@end
