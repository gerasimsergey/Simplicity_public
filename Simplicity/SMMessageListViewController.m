//
//  SMMessageListViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMessageViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMMessageListCellView.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMSimplicityContainer.h"
#import "SMLocalFolder.h"
#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageStorage.h"

@interface SMMessageListViewController()
@property (weak) IBOutlet NSTableView *messageListTableView;
@end

@implementation SMMessageListViewController {
	SMMessageThread *_selectedMessageThread;
	Boolean _reloadMessageThreadSelectionNow;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSInteger messageThreadsCount = [[[appDelegate model] messageStorage] messageThreadsCountInLocalFolder:[currentFolder name]];

//	NSLog(@"%s: self %@, tableView %@, its datasource %@, view %@, messagesTableView %@, message threads count %ld", __FUNCTION__, self, tableView, [tableView dataSource], [self view], _messageListTableView, messageThreadsCount);
	
	return messageThreadsCount;
}

- (void)changeSelection:(NSNumber*)row {
	NSInteger selectedRow = [row integerValue];
	NSAssert(selectedRow >= 0, @"bad row %ld", selectedRow);

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSAssert(currentFolder != nil, @"bad corrent folder");
	
	_selectedMessageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:selectedRow localFolder:[currentFolder name]];
	
	if(_selectedMessageThread != nil) {
		[[[appDelegate appController] messageThreadViewController] setMessageThread:_selectedMessageThread];
	} else {
		[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [ _messageListTableView selectedRow ];
	
	NSLog(@"%s, selected row %lu (current thread id %lld)", __FUNCTION__, selectedRow, _selectedMessageThread != nil? _selectedMessageThread.threadId : -1);

	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // cancel scheduled message list update

	if(selectedRow >= 0) {
		NSNumber *selectedRowNumber = [NSNumber numberWithInteger:selectedRow];
		
		if(_reloadMessageThreadSelectionNow) {
			[self changeSelection:selectedRowNumber];
		} else {
			// delay the selection for a tiny bit to optimize fast cursor movements
			// e.g. when the user uses up/down arrow keys to navigate, skipping many messages between selections
			[self performSelector:@selector(changeSelection:) withObject:selectedRowNumber afterDelay:0.3];
		}
	}

	_reloadMessageThreadSelectionNow = NO;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	NSLog(@"%s: tableView %@, datasource %@, delegate call: %@, row %ld", __FUNCTION__, tableView, [tableView dataSource], [tableColumn identifier], row);
	
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:row localFolder:[currentFolder name]];

	if(messageThread == nil) {
		NSLog(@"%s: row %ld, message thread is nil", __FUNCTION__, row);
		return nil;
	}
	
	NSAssert([messageThread messagesCount], @"no messages in the thread");
	SMMessage *message = [messageThread messagesSortedByDate][0];
	
	SMMessageListCellView *view = [ tableView makeViewWithIdentifier:@"MessageCell" owner:self ];

//	NSLog(@"%s: from '%@', subject '%@'", __FUNCTION__, [message from], [message subject]);
	
	[view.fromTextField setStringValue:[message from]];
	[view.subjectTextField setStringValue:[message subject]];

	NSFont *font = [view.subjectTextField font];
	
	font = messageThread.unseen? [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait] : [[NSFontManager sharedFontManager] convertFont:font toNotHaveTrait:NSFontBoldTrait];

	[view.subjectTextField setFont:font];

	[view.dateTextField setStringValue:[message localizedDate]];
	
	return view;
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
	// for mouse events, react quickly
	_reloadMessageThreadSelectionNow = YES;
}

- (void)reloadMessageList:(Boolean)preserveSelection {
	if(!preserveSelection) {
		[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		_reloadMessageThreadSelectionNow = YES;
	}

	[_messageListTableView reloadData];

	if(preserveSelection && _selectedMessageThread != nil) {
		SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
		SMMessageListController *messageListController = [[appDelegate model] messageListController];
		SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
		
		NSUInteger threadIndex = [[[appDelegate model] messageStorage] getMessageThreadIndexByDate:_selectedMessageThread localFolder:currentFolder.name];
		
		NSIndexSet *threadIndexSet = [NSIndexSet indexSet];

		if(threadIndex != NSNotFound) {
			threadIndexSet = [NSIndexSet indexSetWithIndex:threadIndex];
		} else {
			_selectedMessageThread = nil;
		}

		if(![[_messageListTableView selectedRowIndexes] isEqualToIndexSet:threadIndexSet]) {
			[_messageListTableView selectRowIndexes:threadIndexSet byExtendingSelection:NO];
			_reloadMessageThreadSelectionNow = YES;
		}
	} else {
		_selectedMessageThread = nil;
	}
}

- (IBAction)updateMessages:(id)sender {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];

	[messageListController scheduleMessageListUpdate:YES];

	[_updatingMessagesProgressIndicator setHidden:NO];
	[_updatingMessagesProgressIndicator startAnimation:self];
}

- (IBAction)loadMoreMessages:(id)sender {
//	NSLog(@"%s: sender %@", __func__, sender);

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];

	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	if(currentFolder != nil && [currentFolder messageHeadersAreBeingLoaded] == NO) {
		[currentFolder increaseLocalFolderCapacity];
		[messageListController scheduleMessageListUpdate:YES];

		[_loadingMoreMessagesProgressIndicator setHidden:NO];
		[_loadingMoreMessagesProgressIndicator startAnimation:self];
	}
}

- (void)messageHeadersSyncFinished {
	[_updatingMessagesProgressIndicator stopAnimation:self];
	[_loadingMoreMessagesProgressIndicator stopAnimation:self];

	const Boolean preserveSelection = YES;
	[self reloadMessageList:preserveSelection];

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	[[[appDelegate appController] messageThreadViewController] updateMessageThread];
}

@end
