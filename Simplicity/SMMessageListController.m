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
#import "SMAppDelegate.h"
#import "SMAppController.h"

#define MAX_MESSAGE_HEADERS_TO_FETCH 300
#define MESSAGE_HEADERS_TO_FETCH_AT_ONCE 20
#define MESSAGE_LIST_UPDATE_INTERVAL_SEC 15

#define SEARCH_RESULTS_FOLDER @"//search_results//" // TODO: fix by introducing folder descriptor

@interface Folder : NSObject
@property NSString* name;
@property uint64_t totalMessagesCount;
@property uint64_t messageHeadersFetched;
@property NSMutableArray* fetchedMessageHeaders;
@end

@implementation Folder

- (id)initWithName:(NSString*)name {
	self = [ super init ];
	
	if(self) {
		_name = name;
		_totalMessagesCount = 0;
		_messageHeadersFetched = 0;
		_fetchedMessageHeaders = [NSMutableArray new];
	}
	
	return self;
}

@end

@interface SMMessageListController()
- (void)startMessagesUpdate;
@end

@implementation SMMessageListController {
	__weak SMSimplicityContainer *_model;
	NSMutableDictionary *_folders;
	Folder *_currentFolder;
	MCOIMAPFolderInfoOperation *_folderInfoOp;
	MCOIMAPFetchMessagesOperation *_fetchMessageHeadersOp;
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
	}

	return self;
}

- (NSString*)currentFolder {
	return [_currentFolder name];
}

- (void)changeFolderInternal:(NSString*)folderName {
	NSLog(@"%s: new folder '%@'", __FUNCTION__, folderName);
	
	Folder *folder = [_folders objectForKey:folderName];
	if(folder == nil) {
		folder = [[Folder alloc] initWithName:folderName];
		[_folders setValue:folder forKey:folderName];
	}
	
	[[_model messageStorage] ensureFolderExists:folderName];
	
	_currentFolder = folder;
	
	[_folderInfoOp cancel];
	_folderInfoOp = nil;
	
	[_fetchMessageHeadersOp cancel];
	_fetchMessageHeadersOp = nil;
	
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
			
			[self fetchMessageHeaders];
		}
	}];
}

- (void)loadSearchResults:(MCOIndexSet*)searchResults folderToSearch:(NSString*)folderToSearch {
	[self changeFolderInternal:SEARCH_RESULTS_FOLDER];
	
	_currentFolder.messageHeadersFetched = 0;
	
	[[_model messageStorage] startUpdate:[_currentFolder name]];

	_currentFolder.totalMessagesCount = searchResults.count;
	
	[self loadSearchResultsInternal:searchResults folderToSearch:folderToSearch];
}

- (void)loadSearchResultsInternal:(MCOIndexSet*)searchResults folderToSearch:(NSString*)folderToSearch {
	NSAssert(searchResults != nil && searchResults.count > 0, @"bad search results");
	
	NSAssert(_model != nil, @"model disposed");
	
	MCOIMAPSession *session = [_model session];
	
	NSAssert(session, @"session lost");

	BOOL finishFetch = YES;
	
	if([_currentFolder totalMessagesCount] == [_currentFolder messageHeadersFetched]) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, [_currentFolder totalMessagesCount]);
	} else if([_currentFolder messageHeadersFetched] >= MAX_MESSAGE_HEADERS_TO_FETCH) {
		// TODO: implement and on-demand "load more results" scheme
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, [_currentFolder messageHeadersFetched]);
	} else {
		finishFetch = NO;
	}
	
	if(finishFetch) {
		[[_model messageStorage] endUpdate:[_currentFolder name]];

		[self fetchMessageBodies:folderToSearch];
		
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
	
	NSAssert(_fetchMessageHeadersOp == nil, @"previous search op not cleared");
	
	_fetchMessageHeadersOp = [session fetchMessagesByUIDOperationWithFolder:folderToSearch requestKind:messageHeadersRequestKind uids:searchResultsToLoad];
	
	[_fetchMessageHeadersOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		_fetchMessageHeadersOp = nil;
		
		if(error == nil) {
			NSLog(@"%s: loaded %lu message headers...", __func__, messages.count);
			
			_currentFolder.messageHeadersFetched += [messages count];
			
			[self updateMessageList:messages remoteFolder:folderToSearch];
			
			[self loadSearchResultsInternal:searchResults folderToSearch:folderToSearch];
		} else {
			NSLog(@"%s: Error downloading search results: %@", __func__, error);
		}
	}];
}

- (void)fetchMessageHeaders {
	NSAssert([_currentFolder messageHeadersFetched] <= [_currentFolder totalMessagesCount], @"invalid messageHeadersFetched");
	
	BOOL finishFetch = YES;
	
	if([_currentFolder totalMessagesCount] == [_currentFolder messageHeadersFetched]) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, [_currentFolder totalMessagesCount]);
	} else if([_currentFolder messageHeadersFetched] >= MAX_MESSAGE_HEADERS_TO_FETCH) {
		// TODO: implement and on-demand "load more results" scheme
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, [_currentFolder messageHeadersFetched]);
	} else {
		finishFetch = NO;
	}
	
	if(finishFetch) {
		[[_model messageStorage] endUpdate:[_currentFolder name]];
		
		[_fetchMessageHeadersOp cancel];
		_fetchMessageHeadersOp = nil;
		
		[self fetchMessageBodies:[_currentFolder name]];
		[self scheduleMessageListUpdate];

		return;
	}

	const uint64_t restOfMessages = [_currentFolder totalMessagesCount] - [_currentFolder messageHeadersFetched];
	const uint64_t numberOfMessagesToFetch = MIN(restOfMessages, MESSAGE_HEADERS_TO_FETCH_AT_ONCE) - 1;
	const uint64_t fetchMessagesFromIndex = restOfMessages - numberOfMessagesToFetch;

	MCOIndexSet *regionToFetch = [MCOIndexSet indexSetWithRange:MCORangeMake(fetchMessagesFromIndex, numberOfMessagesToFetch)];
	MCOIMAPSession *session = [ _model session ];
	
	// TODO: handle session reopening/uids validation
	
	NSAssert(session, @"session lost");
	
	NSAssert(_fetchMessageHeadersOp == nil, @"previous search op not cleared");

	_fetchMessageHeadersOp = [session fetchMessagesByNumberOperationWithFolder:[_currentFolder name] requestKind:messageHeadersRequestKind numbers:regionToFetch];
	
	[_fetchMessageHeadersOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		_fetchMessageHeadersOp = nil;
		
		if(error == nil) {
			_currentFolder.messageHeadersFetched += [messages count];

			[self updateMessageList:messages remoteFolder:[_currentFolder name]];
			[self fetchMessageHeaders];
		} else {
			NSLog(@"Error downloading messages list: %@", error);
		}
	}];	
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

- (void)fetchMessageBodies:(NSString*)remoteFolder {
//	NSLog(@"%s: fetching message bodies for folder '%@'", __FUNCTION__, remoteFolder);
	
	NSUInteger fetchCount = 0;
	
	for(MCOIMAPMessage *message in _currentFolder.fetchedMessageHeaders) {
		if([self fetchMessageBody:[message uid] remoteFolder:remoteFolder threadId:[message gmailThreadID] urgent:NO])
			fetchCount++;
	}

	[_currentFolder.fetchedMessageHeaders removeAllObjects];
}

- (BOOL)fetchMessageBody:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId urgent:(BOOL)urgent {
//	NSLog(@"%s: uid %u, remote folder %@, threadId %llu, urgent %s", __FUNCTION__, uid, remoteFolder, threadId, urgent? "YES" : "NO");

	if([[_model messageStorage] messageHasData:uid localFolder:[_currentFolder name] threadId:threadId])
		return NO;

	MCOIMAPSession *session = [_model session];
	
	NSAssert(session, @"session is nil");
	
	MCOIMAPFetchContentOperation * op = [session fetchMessageByUIDOperationWithFolder:remoteFolder uid:uid urgent:urgent];
	
	// TODO: this op should be stored in the a message property
	// TODO: don't fetch if body is already being fetched (non-urgently!)
	// TODO: if urgent fetch is requested, cancel the non-urgent fetch
	[op start:^(NSError * error, NSData * data) {
		if ([error code] != MCOErrorNone) {
			NSLog(@"Error downloading message body for uid %u, remote folder %@", uid, remoteFolder);
			return;
		}
		
		NSAssert(data != nil, @"data != nil");
		
//		NSLog(@"%s: msg uid %u", __FUNCTION__, uid);
		
		NSAssert(_model, @"model is disposed");
		
		[[_model messageStorage] setMessageData:data uid:uid localFolder:[_currentFolder name] threadId:threadId];
		
		NSDictionary *messageInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:uid], [NSNumber numberWithUnsignedLongLong:threadId], nil] forKeys:[NSArray arrayWithObjects:@"UID", @"ThreadId", nil]];
		
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		SMAppController *appController = [appDelegate appController];
		SMMessageThread *currentMessageThread = [[appController messageThreadViewController] currentMessageThread];
		
		if(currentMessageThread != nil && [currentMessageThread threadId] == threadId) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageBodyFetched" object:nil userInfo:messageInfo];
		}
	}];

	return YES;
}

- (void)fetchMessageBodyUrgently:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId {
	NSLog(@"%s: msg uid %u, remote folder %@, threadId %llu", __FUNCTION__, uid, remoteFolder, threadId);

	[self fetchMessageBody:uid remoteFolder:remoteFolder threadId:threadId urgent:YES];
}

@end
