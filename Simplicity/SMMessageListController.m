//
//  SMMessageListUpdater.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/12/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMSimplicityContainer.h"
#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageStorage.h"
#import "SMLocalFolderRegistry.h"
#import "SMLocalFolder.h"
#import "SMAppDelegate.h"
#import "SMAppController.h"

static NSUInteger MESSAGE_LIST_UPDATE_INTERVAL_SEC = 15;

@interface SMMessageListController()
- (void)startMessagesUpdate;
@end

@implementation SMMessageListController {
	__weak SMSimplicityContainer *_model;
	SMLocalFolder *_currentFolder;
	MCOIMAPFolderInfoOperation *_folderInfoOp;
}

- (id)initWithModel:(SMSimplicityContainer*)model {
	self = [ super init ];
	
	if(self) {
		_model = model;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageHeadersFetched:) name:@"MessageHeadersFetched" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageHeadersSyncFinished:) name:@"MessageHeadersSyncFinished" object:nil];
	}

	return self;
}

- (SMLocalFolder*)currentLocalFolder {
	return _currentFolder;
}

- (void)changeFolderInternal:(NSString*)folderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder {
	NSLog(@"%s: new folder '%@'", __FUNCTION__, folderName);

	NSAssert(folderName != nil, @"no folder name");
	
	SMLocalFolder *folder = [[_model localFolderRegistry] getOrCreateLocalFolder:folderName syncWithRemoteFolder:syncWithRemoteFolder];
	NSAssert(folder != nil, @"folder registry returned nil folder");

	if([_currentFolder syncedWithRemoteFolder])
		[_currentFolder stopMessagesLoading:NO];

	_currentFolder = folder;
	
	[_folderInfoOp cancel];
	_folderInfoOp = nil;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // cancel scheduled message list update
}

- (void)changeFolder:(NSString*)folder {
	if([_currentFolder.name isEqualToString:folder])
		return;

	[self changeFolderInternal:folder syncWithRemoteFolder:YES];
	[self startMessagesUpdate];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	Boolean preserveSelection = NO;
	[[appController messageListViewController] reloadMessageList:preserveSelection];
}

- (void)clearCurrentFolderSelection {
	NSString *emptyFolderName = @""; // TODO: create a descriptor for empty folder
	
	if([_currentFolder.name isEqualToString:emptyFolderName])
		return;
	
	[self changeFolderInternal:emptyFolderName syncWithRemoteFolder:NO];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	Boolean preserveSelection = NO;
	[[appController messageListViewController] reloadMessageList:preserveSelection];
}

- (void)startMessagesUpdate {
	[_currentFolder startLocalFolderSync];
}

- (void)loadSearchResults:(MCOIndexSet*)searchResults remoteFolderToSearch:(NSString*)remoteFolderToSearch searchResultsLocalFolder:(NSString*)searchResultsLocalFolder {
	[self changeFolderInternal:searchResultsLocalFolder syncWithRemoteFolder:NO];
	
	[_currentFolder loadSelectedMessages:searchResults remoteFolder:remoteFolderToSearch];

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	Boolean preserveSelection = NO;
	[[appController messageListViewController] reloadMessageList:preserveSelection];
}

- (void)updateMessageList:(NSArray*)imapMessages remoteFolder:(NSString*)remoteFolder {
//	NSLog(@"%s: new messages count %lu", __FUNCTION__, (unsigned long)[imapMessages count]);

	MCOIMAPSession *session = [_model session];

	[[_model messageStorage] updateIMAPMessages:imapMessages localFolder:[_currentFolder name] remoteFolder:remoteFolder session:session];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];

	[appController performSelectorOnMainThread:@selector(updateMessageListView) withObject:nil waitUntilDone:NO];
}

- (void)updateMessageThreadView {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[[appController messageThreadViewController] updateMessageThread];
}

- (void)scheduleMessageListUpdate {
	[self performSelector:@selector(startMessagesUpdate) withObject:nil afterDelay:MESSAGE_LIST_UPDATE_INTERVAL_SEC];
}

- (void)forceMessageListUpdate {
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // cancel scheduled message list update

	[self performSelector:@selector(startMessagesUpdate) withObject:nil afterDelay:0];
}

- (void)fetchMessageBodyUrgently:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId {
	//NSLog(@"%s: msg uid %u, remote folder %@, threadId %llu", __FUNCTION__, uid, remoteFolder, threadId);

	[_currentFolder fetchMessageBody:uid remoteFolder:remoteFolder threadId:threadId urgent:YES];
}

- (void)messageHeadersFetched:(NSNotification *)notification {
	NSString *localFolder = [[notification userInfo] objectForKey:@"LocalFolderName"];

	if([_currentFolder.name isEqualToString:localFolder]) {
		NSArray *messages = [[notification userInfo] objectForKey:@"MessagesList"];
		NSString *remoteFolder = [[notification userInfo] objectForKey:@"RemoteFolderName"];

		[self updateMessageList:messages remoteFolder:remoteFolder];
		[self updateMessageThreadView];
	}
}

- (void)messageHeadersSyncFinished:(NSNotification *)notification {
	NSString *localFolder = [[notification userInfo] objectForKey:@"LocalFolderName"];

	if([_currentFolder.name isEqualToString:localFolder]) {
		[self scheduleMessageListUpdate];
	
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMAppController *appController = [appDelegate appController];
		
		[[appController messageListViewController] messageHeadersSyncFinished];
	}
}

@end
