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
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	
	SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
	NSInteger messageThreadsCount = [[[appDelegate model] messageStorage] messageThreadsCountInLocalFolder:[currentFolder name]];

//	NSLog(@"%s: self %@, tableView %@, its datasource %@, view %@, messagesTableView %@, message threads count %ld", __FUNCTION__, self, tableView, [tableView dataSource], [self view], _messageListTableView, messageThreadsCount);
	
	return messageThreadsCount;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [ _messageListTableView selectedRow ];
	
//	NSLog(@"%s, selected row %lu, app delegate %@", __FUNCTION__, selectedRow, [[ NSApplication sharedApplication ] delegate]);

	if(selectedRow >= 0) {
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

- (void)reloadMessageList:(Boolean)preserveSelection {
	if(!preserveSelection)
		[_messageListTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];

	[_messageListTableView reloadData];

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	SMMessageListController *messageListController = [[appDelegate model] messageListController];
	NSIndexSet *threadIndexSet = [NSIndexSet indexSet];

	if(preserveSelection && _selectedMessageThread != nil) {
		SMLocalFolder *currentFolder = [messageListController currentLocalFolder];
		
		NSUInteger threadIndex = [[[appDelegate model] messageStorage] getMessageThreadIndexByDate:_selectedMessageThread localFolder:currentFolder.name];
		
		if(threadIndex != NSNotFound)
			threadIndexSet = [NSIndexSet indexSetWithIndex:threadIndex];
		else
			_selectedMessageThread = nil;
	} else {
		_selectedMessageThread = nil;
	}

	[_messageListTableView selectRowIndexes:threadIndexSet byExtendingSelection:NO];
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
