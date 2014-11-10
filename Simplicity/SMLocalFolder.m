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

static const NSUInteger MAX_MESSAGE_HEADERS_TO_FETCH = 300;
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
	MCOIMAPFetchMessagesOperation *_fetchMessageHeadersOp;
	NSMutableDictionary *_fetchMessageBodyOps;
}

- (id)initWithLocalFolderName:(NSString*)localFolderName {
	self = [ super init ];
	
	if(self) {
		_name = localFolderName;
		_totalMessagesCount = 0;
		_messageHeadersFetched = 0;
		_fetchedMessageHeaders = [NSMutableArray new];
		_fetchMessageBodyOps = [NSMutableDictionary new];
	}
	
	return self;
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
	
	MCOIMAPFetchContentOperation *op = [session fetchMessageByUIDOperationWithFolder:remoteFolder uid:uid urgent:urgent];
	
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

- (void)fetchMessageHeaders {
	NSAssert(_messageHeadersFetched <= _totalMessagesCount, @"invalid messageHeadersFetched");
	
	BOOL finishFetch = YES;
	
	if(_totalMessagesCount == _messageHeadersFetched) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, _totalMessagesCount);
	} else if(_messageHeadersFetched >= MAX_MESSAGE_HEADERS_TO_FETCH) {
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

		[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageHeadersFetchFinished" object:nil userInfo:[NSDictionary dictionaryWithObject:_name forKey:@"LocalFolderName"]];
		
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
			_messageHeadersFetched += [messages count];

			[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageHeadersFetched" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_name, @"LocalFolderName", messages, @"MessagesList", nil]];
			
			[self fetchMessageHeaders];
		} else {
			NSLog(@"Error downloading messages list: %@", error);
		}
	}];	
}

- (void)cancelUpdate {
	[_fetchMessageHeadersOp cancel];
	_fetchMessageHeadersOp = nil;
}

@end
