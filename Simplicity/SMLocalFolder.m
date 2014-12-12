//
//  SMLocalFolder.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/9/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMAppDelegate.h"
#import "SMMessageStorage.h"
#import "SMAppController.h"
#import "SMLocalFolder.h"

static const NSUInteger DEFAULT_MAX_MESSAGES_PER_FOLDER = 300;
static const NSUInteger INCREASE_MESSAGES_PER_FOLDER = 50;
static const NSUInteger MESSAGE_HEADERS_TO_FETCH_AT_ONCE = 20;

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

@implementation SMLocalFolder {
	MCOIMAPFolderInfoOperation *_folderInfoOp;
	MCOIMAPFetchMessagesOperation *_fetchMessageHeadersOp;
	NSMutableDictionary *_fetchMessageBodyOps;
	NSMutableArray *_fetchedMessageHeaders;
	Boolean _syncWithRemoteFolder;
}

- (id)initWithLocalFolderName:(NSString*)localFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder {
	self = [ super init ];
	
	if(self) {
		_name = localFolderName;
		_maxMessagesPerLocalFolder = DEFAULT_MAX_MESSAGES_PER_FOLDER;
		_totalMessagesCount = 0;
		_messageHeadersFetched = 0;
		_fetchedMessageHeaders = [NSMutableArray new];
		_fetchMessageBodyOps = [NSMutableDictionary new];
		_syncWithRemoteFolder = syncWithRemoteFolder;
	}
	
	return self;
}

- (void)startRemoteFolderSync {
	if(!_syncWithRemoteFolder) {
		NSLog(@"%s: folder %@ is not synched with server", __func__, _name);
		return;
	}
	
	if(_folderInfoOp != nil || _fetchMessageHeadersOp != nil) {
		NSLog(@"%s: previous op is still in progress for folder %@", __func__, _name);
		return;
	}
	
	_messageHeadersFetched = 0;
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	[[[appDelegate model] messageStorage] startUpdate:_name];
	
	MCOIMAPSession *session = [[appDelegate model] session];
	
	NSAssert(session, @"session lost");

	// TODO: handle session reopening/uids validation	
	
	_folderInfoOp = [session folderInfoOperation:_name];
	
	[_folderInfoOp start:^(NSError *error, MCOIMAPFolderInfo *info) {
		_folderInfoOp = nil;
		
		if(error == nil) {
			NSLog(@"UIDNEXT: %lu", (unsigned long) [info uidNext]);
			NSLog(@"UIDVALIDITY: %lu", (unsigned long) [info uidValidity]);
			NSLog(@"Messages count %u", [info messageCount]);
			
			_totalMessagesCount = [info messageCount];
			
			[self syncFetchMessageHeaders];
		} else {
			NSLog(@"Error fetching folder info: %@", error);
		}
	}];
}

- (void)increaseLocalFolderCapacity {
	if(![self folderUpdateIsInProgress]) {
		if(_messageHeadersFetched + INCREASE_MESSAGES_PER_FOLDER < _totalMessagesCount)
			_maxMessagesPerLocalFolder += INCREASE_MESSAGES_PER_FOLDER;
	}
}

- (Boolean)folderUpdateIsInProgress {
	return _folderInfoOp != nil || _fetchMessageHeadersOp != nil;
}

- (void)stopRemoteFolderSync {
	if(!_syncWithRemoteFolder) {
		NSLog(@"%s: folder %@ is not synched with server", __func__, _name);
		return;
	}
	
	[_folderInfoOp cancel];
	_folderInfoOp = nil;
	
	[_fetchMessageHeadersOp cancel];
	_fetchMessageHeadersOp = nil;
	
	// TODO: cancel bodies fetch as well?
	// TODO: how to cancel ops for non-synched folders?
}

- (void)fetchMessageBodies:(NSString*)remoteFolder {
	//	NSLog(@"%s: fetching message bodies for folder '%@'", __FUNCTION__, remoteFolder);
	
	NSUInteger fetchCount = 0;
	
	for(MCOIMAPMessage *message in _fetchedMessageHeaders) {
		if([self fetchMessageBody:[message uid] remoteFolder:remoteFolder threadId:[message gmailThreadID] urgent:NO])
			fetchCount++;
	}
	
	[_fetchedMessageHeaders removeAllObjects];
}

- (BOOL)fetchMessageBody:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId urgent:(BOOL)urgent {
	//	NSLog(@"%s: uid %u, remote folder %@, threadId %llu, urgent %s", __FUNCTION__, uid, remoteFolder, threadId, urgent? "YES" : "NO");

	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];

	if([[[appDelegate model] messageStorage] messageHasData:uid localFolder:_name threadId:threadId])
		return NO;
	
	MCOIMAPSession *session = [[appDelegate model] session];
	
	NSAssert(session, @"session is nil");
	
	MCOIMAPFetchContentOperation *op = [session fetchMessageOperationWithFolder:remoteFolder uid:uid urgent:urgent];
	
	[_fetchMessageBodyOps setObject:op forKey:[NSNumber numberWithUnsignedInt:uid]];
	
	// TODO: don't fetch if body is already being fetched (non-urgently!)
	// TODO: if urgent fetch is requested, cancel the non-urgent fetch
	[op start:^(NSError * error, NSData * data) {
		[_fetchMessageBodyOps removeObjectForKey:[NSNumber numberWithUnsignedInt:uid]];

		if ([error code] != MCOErrorNone) {
			NSLog(@"Error downloading message body for uid %u, remote folder %@", uid, remoteFolder);
			return;
		}

		NSAssert(data != nil, @"data != nil");

		//	NSLog(@"%s: msg uid %u", __FUNCTION__, uid);
		
		[[[appDelegate model] messageStorage] setMessageData:data uid:uid localFolder:_name threadId:threadId];
		
		NSDictionary *messageInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:uid], [NSNumber numberWithUnsignedLongLong:threadId], nil] forKeys:[NSArray arrayWithObjects:@"UID", @"ThreadId", nil]];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageBodyFetched" object:nil userInfo:messageInfo];
	}];
	
	return YES;
}

- (void)syncFetchMessageHeaders {
	NSAssert(_messageHeadersFetched <= _totalMessagesCount, @"invalid messageHeadersFetched");
	
	BOOL finishFetch = YES;
	
	if(_totalMessagesCount == _messageHeadersFetched) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, _totalMessagesCount);
	} else if(_messageHeadersFetched >= _maxMessagesPerLocalFolder) {
		// TODO: implement and on-demand "load more results" scheme
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, _messageHeadersFetched);
	} else {
		finishFetch = NO;
	}
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];

	if(finishFetch) {
		[[[appDelegate model] messageStorage] endUpdate:_name];

		[_fetchMessageHeadersOp cancel];
		_fetchMessageHeadersOp = nil;
		
		[self fetchMessageBodies:_name];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageHeadersSyncFinished" object:nil userInfo:[NSDictionary dictionaryWithObject:_name forKey:@"LocalFolderName"]];
		
		return;
	}
	
	const uint64_t restOfMessages = _totalMessagesCount - _messageHeadersFetched;
	const uint64_t numberOfMessagesToFetch = MIN(restOfMessages, MESSAGE_HEADERS_TO_FETCH_AT_ONCE) - 1;
	const uint64_t fetchMessagesFromIndex = restOfMessages - numberOfMessagesToFetch;
	
	MCOIndexSet *regionToFetch = [MCOIndexSet indexSetWithRange:MCORangeMake(fetchMessagesFromIndex, numberOfMessagesToFetch)];
	MCOIMAPSession *session = [[appDelegate model] session];
	
	// TODO: handle session reopening/uids validation
	
	NSAssert(session, @"session lost");

	NSAssert(_fetchMessageHeadersOp == nil, @"previous search op not cleared");
	
	_fetchMessageHeadersOp = [session fetchMessagesByNumberOperationWithFolder:_name requestKind:messageHeadersRequestKind numbers:regionToFetch];
	
	[_fetchMessageHeadersOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		_fetchMessageHeadersOp = nil;
		
		if(error == nil) {
			[_fetchedMessageHeaders addObjectsFromArray:messages];

			_messageHeadersFetched += [messages count];

			[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageHeadersFetched" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_name, @"LocalFolderName", _name, @"RemoteFolderName", messages, @"MessagesList", nil]];
			
			[self syncFetchMessageHeaders];
		} else {
			NSLog(@"Error downloading messages list: %@", error);
		}
	}];	
}

- (void)loadMessages:(MCOIndexSet*)messageUIDs remoteFolder:(NSString*)remoteFolder {
	_messageHeadersFetched = 0;

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

	[[[appDelegate model] messageStorage] startUpdate:_name];
	
	_totalMessagesCount = messageUIDs.count;
	
	[self loadMessagesInternal:messageUIDs remoteFolder:remoteFolder];
}

- (void)loadMessagesInternal:(MCOIndexSet*)messageUIDs remoteFolder:(NSString*)remoteFolder {
	NSAssert(messageUIDs != nil, @"bad message uids array");
	NSAssert(remoteFolder != nil, @"bad remote folder");
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	MCOIMAPSession *session = [[appDelegate model] session];
	
	NSAssert(session, @"session lost");
	
	BOOL finishFetch = YES;
	
	if(_totalMessagesCount == _messageHeadersFetched) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, _totalMessagesCount);
	} else if(_messageHeadersFetched >= _maxMessagesPerLocalFolder) {
		// TODO: implement and on-demand "load more results" scheme
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, _messageHeadersFetched);
	} else if(messageUIDs.count > 0) {
		finishFetch = NO;
	}
	
	if(finishFetch) {
		[[[appDelegate model] messageStorage] endUpdate:_name];
		
		[self fetchMessageBodies:remoteFolder];
		
		return;
	}
	
	MCOIndexSet *const messageUIDsToLoadNow = [MCOIndexSet indexSet];
	MCORange *const ranges = [messageUIDs allRanges];
	
	for(unsigned int i = [messageUIDs rangesCount]; i > 0; i--) {
		const MCORange currentRange = ranges[i-1];
		const uint64_t len = MCORangeRightBound(currentRange) - MCORangeLeftBound(currentRange) + 1;
		const uint64_t maxCountToLoad = MESSAGE_HEADERS_TO_FETCH_AT_ONCE - messageUIDsToLoadNow.count;
		
		if(len < maxCountToLoad) {
			[messageUIDsToLoadNow addRange:currentRange];
		} else {
			// note: "- 1" is because zero length means one element range
			const MCORange range = MCORangeMake(MCORangeRightBound(currentRange) - maxCountToLoad + 1, maxCountToLoad - 1);
			
			[messageUIDsToLoadNow addRange:range];
			
			break;
		}
	}
	
	NSLog(@"%s: loading %u of %u search results...", __func__, messageUIDsToLoadNow.count, messageUIDs.count);
	
	[messageUIDs removeIndexSet:messageUIDsToLoadNow];
	
	NSAssert(_fetchMessageHeadersOp == nil, @"previous search op not cleared");
	
	_fetchMessageHeadersOp = [session fetchMessagesOperationWithFolder:remoteFolder requestKind:messageHeadersRequestKind uids:messageUIDsToLoadNow];
	
	[_fetchMessageHeadersOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		_fetchMessageHeadersOp = nil;
		
		if(error == nil) {
			NSLog(@"%s: loaded %lu message headers...", __func__, messages.count);

			_messageHeadersFetched += [messages count];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageHeadersFetched" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_name, @"LocalFolderName", remoteFolder, @"RemoteFolderName", messages, @"MessagesList", nil]];
			
			[self loadMessagesInternal:messageUIDs remoteFolder:remoteFolder];
		} else {
			NSLog(@"%s: Error downloading search results: %@", __func__, error);
		}
	}];
}

- (Boolean)messageHeadersAreBeingLoaded {
	return _folderInfoOp != nil && _fetchMessageHeadersOp != nil;
}

- (void)stopMessageHeadersLoading {
	[_fetchMessageHeadersOp cancel];
	_fetchMessageHeadersOp = nil;
}


- (void)stopMessagesLoading {
	[_folderInfoOp cancel];
	_folderInfoOp = nil;

	[self stopMessageHeadersLoading];

	for(id key in _fetchMessageBodyOps) {
		NSNumber *uid = key;
		MCOIMAPFetchContentOperation *op = [_fetchMessageBodyOps objectForKey:uid];

		[op cancel];
	}
	
	[_fetchMessageBodyOps removeAllObjects];
}

- (void)clear {
	[self stopMessagesLoading];
	
	[_fetchedMessageHeaders removeAllObjects];

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[[appDelegate model] messageStorage] removeLocalFolder:_name];
}

@end
