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
#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageStorage.h"

@implementation SMMessageListViewController {
	SMMessage *_currentlyViewedMessage;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	NSInteger messageThreadsCount = [[ [ appDelegate model ] messageStorage ] messageThreadsCount ];

	NSLog(@"%s: self %@, tableView %@, its datasource %@, view %@, messagesTableView %@, message threads count %ld", __FUNCTION__, self, tableView, [tableView dataSource], [self view], _messageListTableView, messageThreadsCount);
	
	return messageThreadsCount;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selectedRow = [ _messageListTableView selectedRow ];
	
	NSLog(@"%s, selected row %lu, app delegate %@", __FUNCTION__, selectedRow, [[ NSApplication sharedApplication ] delegate]);

	if(selectedRow >= 0) {
		SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
		SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:selectedRow];
		
		NSAssert(messageThread, @"messageThread == 0");

		[[[appDelegate appController] messageThreadViewController] setMessageThread:messageThread];
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSLog(@"%s: tableView %@, datasource %@, delegate call: %@, row %ld", __FUNCTION__, tableView, [tableView dataSource], [tableColumn identifier], row);
	
	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMMessageThread *messageThread = [[[appDelegate model] messageStorage] messageThreadAtIndexByDate:row ];
	
	if(messageThread == nil) {
		NSLog(@"%s: row %ld, message thread is nil", __FUNCTION__, row);
		return nil;
	}
	
	NSAssert([messageThread messagesCount], @"no messages in the thread");
	SMMessage *message = [messageThread messagesSortedByDate][0];
	
	SMMessageListCellView *view = [ tableView makeViewWithIdentifier:@"MessageCell" owner:self ];

	NSLog(@"%s: from '%@', subject '%@'", __FUNCTION__, [message from], [message subject]);
	
	[ view.fromTextField setStringValue:[message from] ];
	[ view.subjectTextField setStringValue:[message subject] ];
	
	NSDate *messageDate = [message date];
	NSDateComponents *messageDateComponents = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[message date]];

	NSDateComponents *today = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];

	if([today day] == [messageDateComponents day] && [today month] == [messageDateComponents month] && [today year] == [messageDateComponents year] && [today era] == [messageDateComponents era]) {
		[ view.dateTextField setStringValue:[NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
	} else {
		[ view.dateTextField setStringValue:[NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
	}

	return view;
}

- (void)updateMessageListView {
	//NSLog(@"%s: self %@, view %@, _messageListTableView %@", __FUNCTION__, self, [self view], _messageListTableView);
	//NSLog(@"%s: tableView %@, its datasource %@", __FUNCTION__, _messageListTableView, [ _messageListTableView dataSource ]);

	NSInteger selectedRow = [ _messageListTableView selectedRow ];

	[ _messageListTableView reloadData ];

	// TODO: this won't work if messages are added to the beginning of the list
	[ _messageListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO ];
}

@end
