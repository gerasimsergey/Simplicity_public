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
	SMMessageThread *_currentMessageThread;
	NSMutableArray *_threadCellControllers;
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
	
	[_threadCellControllers removeAllObjects];
	
	_contentView = [[NSView alloc] initWithFrame:[_messageThreadView frame]];
	_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	
	NSArray *messages = [_currentMessageThread messagesSortedByDate];
	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessage *message = messages[i];
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
			
			[messageThreadCellViewController setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[message remoteFolder]];
		} else {
			NSLog(@"%s: no message body!", __FUNCTION__);
			
			[messageListController fetchMessageBodyUrgently:[message uid] remoteFolder:[message remoteFolder] threadId:[_currentMessageThread threadId]];
		}
		
		[messageViewController setMessageDetails:message];
		
		NSView *subview = [messageThreadCellViewController view];
		
		[_contentView addSubview:subview];
	}
	
	[_messageThreadView setDocumentView:_contentView];

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
