//
//  SMMessageListViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMImageRegistry.h"
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

@implementation SMMessageListViewController {
	SMMessageThread *_selectedMessageThread;
	Boolean _delayReloadMessageSelection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	if(self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageBodyFetched:) name:@"MessageBodyFetched" object:nil];
	}

	return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSInteger messageThreadsCount = [[[appDelegate model] messageStorage] messageThreadsCountInLocalFolder:[currentFolder name]];

//	NSLog(@"%s: self %@, tableView %@, its datasource %@, view %@, messagesTableView %@, message threads count %ld", __FUNCTION__, self, tableView, [tableView dataSource], [self view], _messageListTableView, messageThreadsCount);
	
	return messageThreadsCount;
}

- (void)changeSelection:(NSNumber*)row delayed:(Boolean)delayed {
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

- (void)changeSelectionDelayed:(NSNumber*)row {
	[self changeSelection:row delayed:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [ _messageListTableView selectedRow ];
	
	//NSLog(@"%s, selected row %lu (current thread id %lld)", __FUNCTION__, selectedRow, _selectedMessageThread != nil? _selectedMessageThread.threadId : -1);

	if(selectedRow >= 0) {
		NSNumber *selectedRowNumber = [NSNumber numberWithInteger:selectedRow];
		
		if(!_delayReloadMessageSelection) {
			[self changeSelection:selectedRowNumber delayed:NO];
		} else {
			// delay the selection for a tiny bit to optimize fast cursor movements
			// e.g. when the user uses up/down arrow keys to navigate, skipping many messages between selections
			[self performSelector:@selector(changeSelectionDelayed:) withObject:selectedRowNumber afterDelay:0.3];
		}
	}
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
	
	SMMessageListCellView *view = [tableView makeViewWithIdentifier:@"MessageCell" owner:self];
	NSAssert(view != nil, @"view is nil");

	[view initFields];

//	NSLog(@"%s: from '%@', subject '%@'", __FUNCTION__, [message from], [message subject]);
	
	[view.fromTextField setStringValue:[message from]];
	[view.subjectTextField setStringValue:[message subject]];
	[view.dateTextField setStringValue:[message localizedDate]];

	if(messageThread.unseen) {
		[view.unseenImage setImage:appDelegate.imageRegistry.blueCircleImage];
		[view.unseenImage setHidden:NO];
	} else {
		[view.unseenImage setHidden:YES];
	}

	if(messageThread.flagged) {
		[view.starImage setImage:appDelegate.imageRegistry.yellowStarImage];
		[view.starImage setHidden:NO];
	} else {
		[view.starImage setHidden:YES];
	}

	if(messageThread.hasAttachments) {
		[view showAttachmentImage];
	} else {
		[view hideAttachmentImage];
	}
	
	return view;
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
	// cancel scheduled message list update coming from keyboard
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	// for mouse events, react quickly
	_delayReloadMessageSelection = NO;
}

- (void)reloadMessageList:(Boolean)preserveSelection {
	if(!preserveSelection) {
		[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
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

		if(![[_messageListTableView selectedRowIndexes] isEqualToIndexSet:threadIndexSet])
			[_messageListTableView selectRowIndexes:threadIndexSet byExtendingSelection:NO];
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

- (void)messageBodyFetched:(NSNotification *)notification {
	NSDictionary *messageInfo = [notification userInfo];
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	
	if(currentFolder != nil) {
		uint64_t threadId = [[messageInfo objectForKey:@"ThreadId"] unsignedLongLongValue];
		SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadById:threadId localFolder:currentFolder.name];
		
		if(messageThread != nil) {
			uint32_t uid = [[messageInfo objectForKey:@"UID"] unsignedIntValue];

			if([messageThread updateThreadAttributesFromMessageUID:uid]) {
				NSUInteger threadIndex = [[[appDelegate model] messageStorage] getMessageThreadIndexByDate:messageThread localFolder:currentFolder.name];
				
				if(threadIndex != NSNotFound) {
					[_messageListTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:threadIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
				}
			}
		}
	}
}

@end
