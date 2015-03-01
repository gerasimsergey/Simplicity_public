
//
//  SMMessageThreadViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/2/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageThreadCell.h"
#import "SMMessageThreadCellViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMMessageThreadInfoViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMMessageListController.h"
#import "SMFlippedView.h"
#import "SMAppDelegate.h"
#import "SMAppController.h"

@interface SMMessageThreadViewController()
- (void)messageBodyFetched:(NSNotification *)notification;
- (void)updateMessageView:(uint32_t)uid threadId:(uint64_t)threadId;
@end

@implementation SMMessageThreadViewController {
	SMMessageThreadInfoViewController *_messageThreadInfoViewController;
	NSMutableArray *_cells;
	NSView *_contentView;
	Boolean _findContentsActive;
	NSString *_currentStringToFind;
	Boolean _currentStringToFindMatchCase;
	Boolean _stringOccurrenceMarked;
	NSUInteger _stringOccurrenceMarkedCellIndex;
	NSUInteger _stringOccurrenceMarkedResultIndex;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		NSScrollView *messageThreadView = [[NSScrollView alloc] init];
		
		[messageThreadView setBorderType:NSNoBorder];
		[messageThreadView setHasVerticalScroller:YES];
		[messageThreadView setHasHorizontalScroller:NO];
		[messageThreadView setTranslatesAutoresizingMaskIntoConstraints:NO];

		[self setView:messageThreadView];

		_cells = [NSMutableArray new];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
	}
	
	return self;
}

#pragma mark Setting new message threads

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
	if(_currentMessageThread == messageThread)
		return;

	_currentMessageThread = messageThread;

	if(_messageThreadInfoViewController == nil)
		_messageThreadInfoViewController = [[SMMessageThreadInfoViewController alloc] init];

	[_messageThreadInfoViewController setMessageThread:_currentMessageThread];

	[_cells removeAllObjects];

	NSScrollView *messageThreadView = (NSScrollView*)[self view];

	_contentView = [[SMFlippedView alloc] initWithFrame:[messageThreadView frame]];
	_contentView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[messageThreadView setDocumentView:_contentView];

	[_contentView addSubview:[_messageThreadInfoViewController view]];

	if(_currentMessageThread != nil) {
		NSAssert(_currentMessageThread.messagesCount > 0, @"no messages in message thread");
	
		NSArray *messages = [_currentMessageThread messagesSortedByDate];

		_cells = [NSMutableArray arrayWithCapacity:messages.count];

		for(NSUInteger i = 0; i < messages.count; i++) {
			SMMessage *message = messages[i];
			Boolean collapsed = (messages.count == 1? NO : (_currentMessageThread.unseen? !message.unseen : i > 0));
			SMMessageThreadCellViewController *viewController = [self createMessageThreadCell:messages[i] collapsed:collapsed];

			[viewController enableCollapse:(messages.count > 1)];
			viewController.cellIndex = i;

			[_contentView addSubview:[viewController view]];

			_cells[i] = [[SMMessageThreadCell alloc] initWithMessage:messages[i] viewController:viewController];
		}

		[self setViewConstraints];
	}
	
	// on every message thread switch, we hide the find contents panel
	// because it is presumably needed only when the user means to search the particular message thread
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[appDelegate appController] hideFindContentsPanel];
}

#pragma mark Building visual layout of message threads

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
				if(newMessages[i] != ((SMMessageThreadCell*)_cells[i]).message) {
					equal = NO;
					break;
				}
			}
			
			if(equal) {
				for(NSInteger i = 0; i < _cells.count; i++) {
					SMMessageThreadCell *cell = _cells[i];
					[cell.viewController updateMessage];
				}

				return;
			}
		}
		
		NSLog(@"%s: message thread id %llu has been updated (old message count %lu, new %ld)", __func__, _currentMessageThread.threadId, _cells.count, _currentMessageThread.messagesCount);
		
		// remove old (vanished) messages
		for(NSInteger t = _cells.count; t > 0; t--) {
			NSInteger i = t-1;
			SMMessageThreadCell *cell = _cells[i];
			
			// TODO: use the sorting info for fast search
			if(![newMessages containsObject:cell.message]) {
				[cell.viewController.view removeFromSuperview];
				[_cells removeObjectAtIndex:i];

				if(_stringOccurrenceMarked) {
					if(_stringOccurrenceMarkedCellIndex == i) {
						[self clearStringOccurrenceMarkIndex];
					} else if(i < _stringOccurrenceMarkedCellIndex) {
						_stringOccurrenceMarkedCellIndex--;
					}
				}
			}
		}
		
		// add new messages and update existing
		NSMutableArray *updatedCells = [NSMutableArray arrayWithCapacity:newMessages.count];
		
		for(NSInteger i = 0, j = 0; i < newMessages.count; i++) {
			SMMessage *newMessage = newMessages[i];
			
			if(j >= _cells.count || ((SMMessageThreadCell*)_cells[j]).message != newMessage) {
				SMMessageThreadCellViewController *viewController = [self createMessageThreadCell:newMessage collapsed:YES];
				
				[viewController enableCollapse:(newMessages.count > 1)];
				
				[_contentView addSubview:[viewController view]];
				
				updatedCells[i] = [[SMMessageThreadCell alloc] initWithMessage:newMessage viewController:viewController];
			} else {
				SMMessageThreadCell *cell = _cells[j++];

				[cell.viewController updateMessage];

				updatedCells[i] = cell;
			}

			SMMessageThreadCell *cell = updatedCells[i];
			cell.viewController.cellIndex = i;
		}
		
		// populate the updated view
		_cells = updatedCells;
		
		[_contentView removeConstraints:[_contentView constraints]];
		[self setViewConstraints];
	} else {
		//NSLog(@"%s: message thread id %llu is empty", __func__, _currentMessageThread.threadId);

		[_cells removeAllObjects];
		[_contentView removeConstraints:[_contentView constraints]];
		[_contentView setSubviews:[NSArray array]];

		_currentMessageThread = nil;
	}
}

- (void)setViewConstraints {
	NSView *infoView = [_messageThreadInfoViewController view];
	NSAssert(infoView != nil, @"no info view");

	[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:infoView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
	
	[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:infoView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
	
	[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:infoView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];

	const CGFloat cellSpacing = -1;
	
	if(_cells.count == 1) {
		NSView *subview = ((SMMessageThreadCell*)_cells[0]).viewController.view;

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

		[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:infoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:-cellSpacing]];
	} else {
		NSView *prevSubView = nil;
		
		for(NSInteger i = 0; i < _cells.count; i++) {
			NSView *subview = ((SMMessageThreadCell*)_cells[i]).viewController.view;

			[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];

			[_contentView addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];

			NSLayoutConstraint *topConstraint;

			if(i == 0) {
				topConstraint = [NSLayoutConstraint constraintWithItem:infoView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:-cellSpacing];
			} else {
				topConstraint = [NSLayoutConstraint constraintWithItem:prevSubView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:-cellSpacing];
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
		SMMessageThreadCell *cell = _cells[i];
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

- (void)setCellCollapsed:(Boolean)collapsed cellIndex:(NSUInteger)cellIndex {
	NSAssert(cellIndex < _cells.count, @"bad index %lu", cellIndex);
	
	if(_findContentsActive) {
		SMMessageThreadCell *cell = _cells[cellIndex];

		if(collapsed) {
			[cell.viewController removeAllHighlightedOccurrencesOfString];
			
			if(_stringOccurrenceMarked && _stringOccurrenceMarkedCellIndex == cellIndex)
				[self clearStringOccurrenceMarkIndex];
		} else {
			[cell.viewController highlightAllOccurrencesOfString:_currentStringToFind matchCase:_currentStringToFindMatchCase];
		}
	}
}

#pragma mark Processing incoming notifications

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	[self updateMessageView:[[messageInfo objectForKey:@"UID"] unsignedIntValue] threadId:[[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue]];
}

#pragma mark Finding messages contents

- (void)findContents:(NSString*)stringToFind matchCase:(Boolean)matchCase forward:(Boolean)forward {
	NSAssert(_currentMessageThread != nil, @"_currentMessageThread == nil");
	NSAssert(_cells.count > 0, @"no cells");
	
	SMMessageThreadCell *markedCell = nil;

	if((_currentStringToFind != nil && ![_currentStringToFind isEqualToString:stringToFind]) || !_stringOccurrenceMarked) {
		// this is the case when there is no marked occurrence or the user has lost it
		// which can happen if the message cell is collapsed or vanished due to update
		// so just remove any stale mark and mark the first occurrence in the first cell
		// that has at least one

		if(_stringOccurrenceMarked) {
			NSAssert(_stringOccurrenceMarkedCellIndex < _cells.count, @"_stringOccurrenceMarkedCellIndex %lu, cells count %lu", _stringOccurrenceMarkedCellIndex, _cells.count);

			SMMessageThreadCell *cell = _cells[_stringOccurrenceMarkedCellIndex];
			[cell.viewController removeMarkedOccurrenceOfFoundString];
			
			_stringOccurrenceMarked = NO;
		}

		for(NSUInteger i = 0; i < _cells.count; i++) {
			SMMessageThreadCell *cell = _cells[i];

			if(!cell.viewController.collapsed) {
				[cell.viewController highlightAllOccurrencesOfString:stringToFind matchCase:matchCase];
				
				if(!_stringOccurrenceMarked) {
					if(cell.viewController.stringOccurrencesCount > 0) {
						_stringOccurrenceMarked = YES;
						_stringOccurrenceMarkedCellIndex = i;
						_stringOccurrenceMarkedResultIndex = 0;
						
						[cell.viewController markOccurrenceOfFoundString:_stringOccurrenceMarkedResultIndex];
						
						markedCell = cell;
					}
				}
			}
		}
		
		_currentStringToFind = stringToFind;
		_currentStringToFindMatchCase = matchCase;
	} else {
		// this is the case when there is a marked occurrence already
		// so we just need to move it forward or backwards
		// just scan the cells in the corresponsing direction and choose the right place

		NSAssert(_stringOccurrenceMarked, @"string occurrence not marked");
		NSAssert(_stringOccurrenceMarkedCellIndex < _cells.count, @"_stringOccurrenceMarkedCellIndex %lu, cells count %lu", _stringOccurrenceMarkedCellIndex, _cells.count);

		SMMessageThreadCell *cell = _cells[_stringOccurrenceMarkedCellIndex];
		NSAssert(!cell.viewController.collapsed, @"cell with marked string is collapsed");

		if(forward && _stringOccurrenceMarkedResultIndex+1 < cell.viewController.stringOccurrencesCount) {
			[cell.viewController markOccurrenceOfFoundString:(++_stringOccurrenceMarkedResultIndex)];
		} else if(!forward && _stringOccurrenceMarkedResultIndex > 0) {
			[cell.viewController markOccurrenceOfFoundString:(--_stringOccurrenceMarkedResultIndex)];
		} else {
			[cell.viewController removeMarkedOccurrenceOfFoundString];

			Boolean wrap = NO;
			for(NSUInteger i = _stringOccurrenceMarkedCellIndex;;) {
				if(forward) {
					if(i == _cells.count-1) {
						if(wrap) {
							[self clearStringOccurrenceMarkIndex];
							break;
						} else {
							wrap = YES;
							i = 0;
						}
					} else {
						i++;
					}
				} else {
					if(i == 0) {
						if(wrap) {
							[self clearStringOccurrenceMarkIndex];
							break;
						} else {
							wrap = YES;
							i = _cells.count-1;
						}
					} else {
						i--;
					}
				}
				
				cell = _cells[i];
				
				if(!cell.viewController.collapsed && cell.viewController.stringOccurrencesCount > 0) {
					_stringOccurrenceMarkedResultIndex = forward? 0 : cell.viewController.stringOccurrencesCount-1;
					_stringOccurrenceMarkedCellIndex = i;

					[cell.viewController markOccurrenceOfFoundString:_stringOccurrenceMarkedResultIndex];

					break;
				}
			}
		}

		markedCell = cell;
	}

	// if there is a marked occurrence, make sure it is visible
	// just scroll the thread view to the right cell
	// note that the cell itself will scroll the html text to the marked position
	if(_stringOccurrenceMarked) {
		NSAssert(markedCell != nil, @"no cell");

		NSScrollView *messageThreadView = (NSScrollView*)[self view];
		NSRect visibleRect = [[messageThreadView contentView] documentVisibleRect];
		
		if(markedCell.viewController.view.frame.origin.y < visibleRect.origin.y || markedCell.viewController.view.frame.origin.y + markedCell.viewController.view.frame.size.height >= visibleRect.origin.y + visibleRect.size.height) {
			NSPoint cellPosition = NSMakePoint(messageThreadView.visibleRect.origin.x, markedCell.viewController.view.frame.origin.y);
			[[messageThreadView documentView] scrollPoint:cellPosition];
		}
	}

	_findContentsActive = YES;
}

- (void)removeFindContentsResults {
	NSAssert(_currentMessageThread != nil, @"_currentMessageThread == nil");
	NSAssert(_cells.count > 0, @"no cells");
	
	for(SMMessageThreadCell *cell in _cells)
		[cell.viewController removeAllHighlightedOccurrencesOfString];

	[self clearStringOccurrenceMarkIndex];

	_currentStringToFind = nil;
	_currentStringToFindMatchCase = NO;
	_findContentsActive = NO;
}

- (void)clearStringOccurrenceMarkIndex {
	_stringOccurrenceMarked = NO;
	_stringOccurrenceMarkedCellIndex = 0;
	_stringOccurrenceMarkedResultIndex = 0;
}

- (void)keyDown:(NSEvent *)theEvent {
	if([theEvent keyCode] == 53) { // esc
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		[[appDelegate appController] hideFindContentsPanel];
	} else {
		[super keyDown:theEvent];
	}
}

@end
