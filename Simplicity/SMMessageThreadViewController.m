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

@interface ThreadCell : NSObject
@property SMMessageThreadCellViewController *viewController;
@property SMMessage *message;
- (id)initWithMessage:(SMMessage*)message viewController:(SMMessageThreadCellViewController*)viewController;
@end

@implementation ThreadCell
- (id)initWithMessage:(SMMessage*)message viewController:(SMMessageThreadCellViewController*)viewController {
	self = [super init];
	if(self) {
		_message = message;
		_viewController = viewController;
	}
	return self;
}
@end

@interface SMMessageThreadViewController()
- (void)messageBodyFetched:(NSNotification *)notification;
- (void)updateMessageView:(uint32_t)uid threadId:(uint64_t)threadId;
@end

@implementation SMMessageThreadViewController {
	NSMutableArray *_cells;
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
		
		_cells = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
	}
	
	return self;
}

- (SMMessageThreadCellViewController*)createMessageThreadCell:(SMMessage*)message {
	SMMessageThreadCellViewController *messageThreadCellViewController = [[SMMessageThreadCellViewController alloc] init];
	
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

	[_cells removeAllObjects];

	_contentView = [[NSView alloc] initWithFrame:[_messageThreadView frame]];
	_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	
	if(_currentMessageThread != nil) {
		NSArray *messages = [_currentMessageThread messagesSortedByDate];

		_cells = [NSMutableArray arrayWithCapacity:messages.count];

		for(NSInteger i = 0; i < messages.count; i++) {
			SMMessageThreadCellViewController *messageThreadCellViewController = [self createMessageThreadCell:messages[i]];
			
			if(messages.count > 1)
				[messageThreadCellViewController enableCollapse];

			[_contentView addSubview:[messageThreadCellViewController view]];

			_cells[i] = [[ThreadCell alloc] initWithMessage:messages[i] viewController:messageThreadCellViewController];
		}
		
	}
	
	[_messageThreadView setDocumentView:_contentView];

	[self setViewConstraints];
}

- (void)updateMessageThread {
	if(_currentMessageThread == nil)
		return;

	NSAssert(_cells != nil, @"no cells in the current thread");

	NSArray *newMessages = [_currentMessageThread messagesSortedByDate];
	
	if(newMessages.count > 0) {
		// check whether messages did not change
		if(newMessages.count == _cells.count) {
			Boolean equal = YES;
			
			for(NSInteger i = 0; i < _cells.count; i++) {
				if(newMessages[i] != ((ThreadCell*)_cells[i]).message) {
					equal = NO;
					break;
				}
			}
			
			if(equal)
				return;
		}
		
		NSLog(@"%s: message thread id %llu has been updated (old message count %lu, new %ld)", __func__, _currentMessageThread.threadId, _cells.count, _currentMessageThread.messagesCount);
		
		// remove old (vanished) messages
		for(NSInteger t = _cells.count; t > 0; t--) {
			NSInteger i = t-1;
			ThreadCell *cell = _cells[i];
			
			// TODO: use the sorting info for fast search
			if(![newMessages containsObject:cell.message]) {
				[cell.viewController.view removeFromSuperview];
				[_cells removeObjectAtIndex:i];
			}
		}
		
		// add new messages
		NSMutableArray *updatedCells = [NSMutableArray arrayWithCapacity:newMessages.count];
		
		for(NSInteger i = 0, j = 0; i < newMessages.count; i++) {
			SMMessage *newMessage = newMessages[i];
			
			if(j >= _cells.count || ((ThreadCell*)_cells[j]).message != newMessage) {
				SMMessageThreadCellViewController *viewController = [self createMessageThreadCell:newMessage];
				
				if(newMessages.count > 1)
					[viewController enableCollapse];
				
				[_contentView addSubview:[viewController view]];
				
				updatedCells[i] = [[ThreadCell alloc] initWithMessage:newMessage viewController:viewController];
			} else {
				updatedCells[i] = _cells[j++];
			}
		}
		
		// populate the updated view
		_cells = updatedCells;
		
		[_contentView removeConstraints:[_contentView constraints]];
		[self setViewConstraints];
	} else {
		NSLog(@"%s: message thread id %llu is empty", __func__, _currentMessageThread.threadId);

		[_cells removeAllObjects];

		for(NSView *subview in _contentView.subviews)
			[subview removeFromSuperview];

		[_contentView removeConstraints:[_contentView constraints]];
	}
}

- (void)setViewConstraints {
	if(_cells.count == 1)
	{
		NSView *subview = ((ThreadCell*)_cells[0]).viewController.view;

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
	}
	else
	{
		NSView *prevSubView = nil;
		
		for(NSInteger i = 0; i < _cells.count; i++) {
			NSView *subview = ((ThreadCell*)_cells[i]).viewController.view;

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
	NSAssert(messages.count == _cells.count, @"messages count %ld is inconsistent with cells count %ld", messages.count, _cells.count);

	for(NSInteger i = 0; i < messages.count; i++) {
		SMMessage *message = messages[i];
		
		// TODO: optimize search
		if(message.uid == uid) {
			NSString *htmlMessageBodyText = [message htmlBodyRendering];
			NSAssert(htmlMessageBodyText != nil, @"message has no body");
			
			[message fetchInlineAttachments];
			
			SMMessageThreadCellViewController *viewController = ((ThreadCell*)_cells[i]).viewController;
			
			[viewController setMessageViewText:htmlMessageBodyText uid:[message uid] folder:[message remoteFolder]];
			[[viewController messageViewController] setMessageDetails:message];
			
			break;
		}
	}
}

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	[self updateMessageView:[[messageInfo objectForKey:@"UID"] unsignedIntValue] threadId:[[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue]];
}

@end
