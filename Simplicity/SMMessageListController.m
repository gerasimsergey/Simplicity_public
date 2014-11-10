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
#import "SMLocalFolder.h"
#import "SMAppDelegate.h"
#import "SMAppController.h"

#define MAX_MESSAGE_HEADERS_TO_FETCH 300
#define MESSAGE_HEADERS_TO_FETCH_AT_ONCE 20
#define MESSAGE_LIST_UPDATE_INTERVAL_SEC 15

@interface SMMessageListController()
- (void)startMessagesUpdate;
@end

@implementation SMMessageListController {
	__weak SMSimplicityContainer *_model;
	NSMutableDictionary *_folders;
	SMLocalFolder *_currentFolder;
	MCOIMAPFolderInfoOperation *_folderInfoOp;
}

static const MCOIMAPMessagesRequestKind messageHeadersRequestKind = (MCOIMAPMessagesRequestKind)(
	MCOIMAPMessagesRequestKindHeaders |
	MCOIMAPMessagesRequestKindStructure |
	MCOIMAPMessagesRequestKindFullHeaders    |
	MCOIMAPMessagesRequestKindInternalDate |
	MCOIMAPMessagesRequestKindHeaderSubject |
	MCOIMAPMessagesRequestKindFlags |
	MCOIMAPMessagesRequestKindGmailLabels |
	MCOIMAPMessagesRequestKindGmailMessageID |
	MCOIMAPMessagesRequestKindGmailThreadID
);

- (id)initWithModel:(SMSimplicityContainer*)model {
	self = [ super init ];
	
	if(self) {
		_model = model;
		_folders = [NSMutableDictionary new];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageHeadersFetched:) name:@"MessageHeadersFetched" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageHeadersFetchFinished:) name:@"MessageHeadersFetchFinished" object:nil];
	}

	return self;
}

- (NSString*)currentFolder {
	return [_currentFolder name];
}

- (void)changeFolderInternal:(NSString*)folderName {
	NSLog(@"%s: new folder '%@'", __FUNCTION__, folderName);
	
	NSAssert(folderName != nil, @"no folder name");
	
	SMLocalFolder *folder = [_folders objectForKey:folderName];
	if(folder == nil) {
		folder = [[SMLocalFolder alloc] initWithLocalFolderName:folderName];
		[_folders setValue:folder forKey:folderName];
	}
	
	[[_model messageStorage] ensureFolderExists:folderName];

	// TODO: don't do it for the search results folder
	[_currentFolder cancelUpdate];

	_currentFolder = folder;
	
	[_folderInfoOp cancel];
	_folderInfoOp = nil;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // cancel scheduled message list update
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[[appController messageListViewController] reloadMessageList];
}

- (void)changeFolder:(NSString*)folder {
	if(![_currentFolder.name isEqual:folder]) {
		[self changeFolderInternal:folder];
		[self startMessagesUpdate];
	}
}

- (void)startMessagesUpdate {
	NSAssert(_model != nil, @"model disposed");
	
	//	NSLog(@"%s: imap server capabilities %@", __FUNCTION__, [_model imapServerCapabilities]);
	
	_currentFolder.messageHeadersFetched = 0;
	
	[[_model messageStorage] startUpdate:[_currentFolder name]];
	
	MCOIMAPSession *session = [_model session];
	
	// TODO: handle session reopening/uids validation
	
	NSAssert(session, @"session lost");
	
	MCOIMAPFolderInfoOperation *folderInfoOp = [session folderInfoOperation:[_currentFolder name]];
	
	_folderInfoOp = folderInfoOp;
	
	[folderInfoOp start:^(NSError *error, MCOIMAPFolderInfo *info) {
		NSAssert(_folderInfoOp == folderInfoOp, @"previous folder info op not cancelled");
		
		_folderInfoOp = nil;
		
		if(error) {
			NSLog(@"Error fetching folder info: %@", error);
		} else {
			NSLog(@"UIDNEXT: %lu", (unsigned long) [info uidNext]);
			NSLog(@"UIDVALIDITY: %lu", (unsigned long) [info uidValidity]);
			NSLog(@"Messages count %u", [info messageCount]);
			
			_currentFolder.totalMessagesCount = [info messageCount];
			
			[_currentFolder fetchMessageHeaders];
		}
	}];
}

- (void)loadSearchResults:(MCOIndexSet*)searchResults remoteFolderToSearch:(NSString*)remoteFolderToSearch searchResultsLocalFolder:(NSString*)searchResultsLocalFolder {
	[self changeFolderInternal:searchResultsLocalFolder];

	_currentFolder.messageHeadersFetched = 0;
	
	[[_model messageStorage] startUpdate:[_currentFolder name]];

	_currentFolder.totalMessagesCount = searchResults.count;
	
	[self loadSearchResultsInternal:searchResults remoteFolderToSearch:remoteFolderToSearch];
}

- (void)loadSearchResultsInternal:(MCOIndexSet*)searchResults remoteFolderToSearch:(NSString*)remoteFolderToSearch {
	NSAssert(searchResults != nil, @"bad search results");
	
	NSAssert(_model != nil, @"model disposed");
	
	MCOIMAPSession *session = [_model session];
	
	NSAssert(session, @"session lost");

	BOOL finishFetch = YES;
	
	if([_currentFolder totalMessagesCount] == [_currentFolder messageHeadersFetched]) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, [_currentFolder totalMessagesCount]);
	} else if([_currentFolder messageHeadersFetched] >= MAX_MESSAGE_HEADERS_TO_FETCH) {
		// TODO: implement and on-demand "load more results" scheme
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, [_currentFolder messageHeadersFetched]);
	} else if(searchResults.count > 0) {
		finishFetch = NO;
	}
	
	if(finishFetch) {
		[[_model messageStorage] endUpdate:[_currentFolder name]];

		[_currentFolder fetchMessageBodies:remoteFolderToSearch];
		
		return;
	}

	MCOIndexSet *const searchResultsToLoad = [MCOIndexSet indexSet];
	MCORange *const ranges = [searchResults allRanges];
	
	for(unsigned int i = [searchResults rangesCount]; i > 0; i--) {
		const MCORange currentRange = ranges[i-1];
		const uint64_t len = MCORangeRightBound(currentRange) - MCORangeLeftBound(currentRange) + 1;
		const uint64_t maxCountToLoad = MESSAGE_HEADERS_TO_FETCH_AT_ONCE - searchResultsToLoad.count;
		
		if(len < maxCountToLoad) {
			[searchResultsToLoad addRange:currentRange];
		} else {
			// note: "- 1" is because zero length means one element range
			const MCORange range = MCORangeMake(MCORangeRightBound(currentRange) - maxCountToLoad + 1, maxCountToLoad - 1);

			[searchResultsToLoad addRange:range];
			
			break;
		}
	}
	
	[searchResults removeIndexSet:searchResultsToLoad];
	
	NSLog(@"%s: loading %u of %u search results...", __func__, searchResultsToLoad.count, searchResults.count);

#if 0
	NSAssert(_fetchMessageHeadersOp == nil, @"previous search op not cleared");
	
	_fetchMessageHeadersOp = [session fetchMessagesByUIDOperationWithFolder:remoteFolderToSearch requestKind:messageHeadersRequestKind uids:searchResultsToLoad];
	
	[_fetchMessageHeadersOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		_fetchMessageHeadersOp = nil;
		
		if(error == nil) {
			NSLog(@"%s: loaded %lu message headers...", __func__, messages.count);
			
			_currentFolder.messageHeadersFetched += [messages count];
			
			[self updateMessageList:messages remoteFolder:remoteFolderToSearch];
			
			[self loadSearchResultsInternal:searchResults remoteFolderToSearch:remoteFolderToSearch];
		} else {
			NSLog(@"%s: Error downloading search results: %@", __func__, error);
		}
	}];
#else
	NSAssert(NO, @"search temporaly disabled!");
#endif
}

- (void)updateMessageList:(NSArray*)imapMessages remoteFolder:(NSString*)remoteFolder {
//	NSLog(@"%s: new messages count %lu", __FUNCTION__, (unsigned long)[imapMessages count]);

	MCOIMAPSession *session = [_model session];

	[[_model messageStorage] updateIMAPMessages:imapMessages localFolder:[_currentFolder name] remoteFolder:remoteFolder session:session];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];

	[appController performSelectorOnMainThread:@selector(updateMessageListView) withObject:nil waitUntilDone:NO];

	[_currentFolder.fetchedMessageHeaders addObjectsFromArray:imapMessages];
}

- (void)scheduleMessageListUpdate {
	[self performSelector:@selector(startMessagesUpdate) withObject:nil afterDelay:MESSAGE_LIST_UPDATE_INTERVAL_SEC];
}

- (void)fetchMessageBodyUrgently:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId {
	NSLog(@"%s: msg uid %u, remote folder %@, threadId %llu", __FUNCTION__, uid, remoteFolder, threadId);

	[_currentFolder fetchMessageBody:uid remoteFolder:remoteFolder threadId:threadId urgent:YES];
}

- (void)messageHeadersFetched:(NSNotification *)notification {
	if([_currentFolder.name isEqualToString:[[notification userInfo] objectForKey:@"LocalFolderName"]])
		[self updateMessageList:[[notification userInfo] objectForKey:@"MessagesList"] remoteFolder:_currentFolder.name];
}

- (void)messageHeadersFetchFinished:(NSNotification *)notification {
	if([_currentFolder.name isEqualToString:[[notification userInfo] objectForKey:@"LocalFolderName"]])
		[self scheduleMessageListUpdate];
}

@end
