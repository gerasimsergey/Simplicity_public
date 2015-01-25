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
#import "SMMessageBodyViewController.h"
#import "SMMessageListController.h"
#import "SMFlippedView.h"
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

- (SMMessageThreadCellViewController*)createMessageThreadCell:(SMMessage*)message collapsed:(Boolean)collapsed {
	SMMessageThreadCellViewController *messageThreadCellViewController = [[SMMessageThreadCellViewController alloc] initCollapsed:collapsed];
	
	[messageThreadCellViewController setMessage:message];
	
	if([messageThreadCellViewController loadMessageBody]) {
		[message fetchInlineAttachments];
	} else {
		SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
		SMMessageListController *messageListController = [[appDelegate model] messageListController];

		[messageListController fetchMessageBodyUrgently:[message uid] remoteFolder:[message remoteFolder] threadId:[_currentMessageThread threadId]];
	}
	
	return messageThreadCellViewController;
}

- (void)setMessageThread:(SMMessageThread*)messageThread {
	NSAssert([messageThread messagesCount] > 0, @"no messages in message thread");
	
	if(_currentMessageThread == messageThread)
		return;
	
	_currentMessageThread = messageThread;

	[_cells removeAllObjects];

	_contentView = [[SMFlippedView alloc] initWithFrame:[_messageThreadView frame]];
	_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	
	if(_currentMessageThread != nil) {
		NSArray *messages = [_currentMessageThread messagesSortedByDate];

		_cells = [NSMutableArray arrayWithCapacity:messages.count];

		for(NSInteger i = 0; i < messages.count; i++) {
			SMMessage *message = messages[i];
			Boolean collapsed = (messages.count == 1? NO : (_currentMessageThread.unseen? !message.unseen : i > 0));
			SMMessageThreadCellViewController *viewController = [self createMessageThreadCell:messages[i] collapsed:collapsed];

			[viewController enableCollapse:(messages.count > 1)];

			[_contentView addSubview:[viewController view]];

			_cells[i] = [[ThreadCell alloc] initWithMessage:messages[i] viewController:viewController];
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
			
			if(equal) {
				for(NSInteger i = 0; i < _cells.count; i++) {
					ThreadCell *cell = _cells[i];
					[cell.viewController updateMessage];
				}

				return;
			}
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
		
		// add new messages and update existing
		NSMutableArray *updatedCells = [NSMutableArray arrayWithCapacity:newMessages.count];
		
		for(NSInteger i = 0, j = 0; i < newMessages.count; i++) {
			SMMessage *newMessage = newMessages[i];
			
			if(j >= _cells.count || ((ThreadCell*)_cells[j]).message != newMessage) {
				SMMessageThreadCellViewController *viewController = [self createMessageThreadCell:newMessage collapsed:NO];
				
				[viewController enableCollapse:(newMessages.count > 1)];
				
				[_contentView addSubview:[viewController view]];
				
				updatedCells[i] = [[ThreadCell alloc] initWithMessage:newMessage viewController:viewController];
			} else {
				ThreadCell *cell = _cells[j++];

				[cell.viewController updateMessage];

				updatedCells[i] = cell;
			}
		}
		
		// populate the updated view
		_cells = updatedCells;
		
		[_contentView removeConstraints:[_contentView constraints]];
		[self setViewConstraints];
	} else {
		NSLog(@"%s: message thread id %llu is empty", __func__, _currentMessageThread.threadId);

		[_cells removeAllObjects];
		[_contentView removeConstraints:[_contentView constraints]];
		[_contentView setSubviews:[NSArray array]];
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

	// TODO: optimize search?
	for(NSInteger i = 0; i < _cells.count; i++) {
		ThreadCell *cell = _cells[i];
		SMMessage *message = cell.message;
		
		if(message.uid == uid) {
			[message fetchInlineAttachments];

			[cell.viewController updateMessage];

			if(![cell.viewController loadMessageBody]) {
				NSAssert(FALSE, @"message uid %u (thread id %lld) fetched with no body!!!", uid, threadId);
			}
			
			return;
		}
	}
	
	NSLog(@"%s: message uid %u doesn't belong to thread id %lld", __func__, uid, threadId);
}

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	[self updateMessageView:[[messageInfo objectForKey:@"UID"] unsignedIntValue] threadId:[[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue]];
}

@end
