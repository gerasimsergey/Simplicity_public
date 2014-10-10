//
//  SMMailboxController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 7/4/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMSimplicityContainer.h"
#import "SMMailbox.h"
#import "SMMailboxController.h"

#define FOLDER_LIST_UPDATE_INTERVAL_SEC 5

@implementation SMMailboxController {
	__weak SMSimplicityContainer *_model;
	MCOIMAPFetchFoldersOperation *_fetchFoldersOp;
}

- (id)initWithModel:(SMSimplicityContainer*)model {
	self = [ super init ];
	
	if(self) {
		_model = model;
	}
	
	return self;
}

- (void)scheduleFolderListUpdate {
	[self performSelector:@selector(updateFolders) withObject:nil afterDelay:FOLDER_LIST_UPDATE_INTERVAL_SEC];
}

- (void)updateFolders {
	MCOIMAPSession *session = [ _model session ];
	NSAssert(session != nil, @"session is nil");

	if(_fetchFoldersOp == nil)
		_fetchFoldersOp = [session fetchAllFoldersOperation];
	
	[_fetchFoldersOp start:^(NSError * error, NSArray *folders) {
		if (error != nil && [error code] != MCOErrorNone) {
			NSLog(@"Error downloading folders structure");
			return;
		}
		
		SMMailbox *mailbox = [ _model mailbox ];
		NSAssert(mailbox != nil, @"mailbox is nil");
		
		[mailbox updateIMAPFolders:folders];

		[self scheduleFolderListUpdate];

		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMAppController *appController = [appDelegate appController];

		[appController performSelectorOnMainThread:@selector(updateMailboxFolderListView) withObject:nil waitUntilDone:NO];
	}];
	
}

@end
