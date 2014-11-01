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
#define MESSAGE_HEADERS_TO_FETCH_AT_ONCE 50
#define MESSAGE_LIST_UPDATE_INTERVAL_SEC 15

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

- (void)fetchMessageHeaders;
- (void)fetchMessageBodies;
- (BOOL)fetchMessageBody:(uint32_t)uid threadId:(uint64_t)threadId urgent:(BOOL)urgent;

- (void)updateMessageList:(NSArray*)imapMessages;
- (void)scheduleMessageListUpdate;

@end

@implementation SMMessageListController {
	__weak SMSimplicityContainer *_model;
	NSMutableDictionary *_folders;
	Folder *_currentFolder;
	MCOIMAPFolderInfoOperation *_folderInfoOp;
	MCOIMAPFetchMessagesOperation *_fetchMessageHeadersOp;
}

- (id)initWithModel:(SMSimplicityContainer*)model {
	self = [ super init ];
	
	if(self) {
		_model = model;
		_folders = [NSMutableDictionary new];
	}

	return self;
}

- (void)changeFolder:(NSString*)folderName {
	NSLog(@"%s: new folder '%@'", __FUNCTION__, folderName);
	
	Folder *folder = [_folders objectForKey:folderName];
	if(folder == nil) {
		folder = [[Folder alloc] initWithName:folderName];
		[_folders setValue:folder forKey:folderName];
	}

	[[_model messageStorage] switchFolder:folderName];

	_currentFolder = folder;
	
	[_folderInfoOp cancel];
	_folderInfoOp = nil;
	
	[_fetchMessageHeadersOp cancel];
	_fetchMessageHeadersOp = nil;

	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // ???

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	NSTableView *messageListView = [[appController messageListViewController] messageListTableView];
	
	[messageListView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[messageListView reloadData];
	
	[self startMessagesUpdate];
}

- (void)startMessagesUpdate {
	SMSimplicityContainer *model = _model;
	
	if(!model) {
		NSLog(@"%s: model disposed", __FUNCTION__);
		return;
	}
	
	NSLog(@"%s: imap server capabilities %@", __FUNCTION__, [model imapServerCapabilities]);

	_currentFolder.messageHeadersFetched = 0;
	
	[[_model messageStorage] startUpdate];

	MCOIMAPSession *session = [model session];
	
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

- (void)fetchMessageHeaders {
	NSAssert([_currentFolder messageHeadersFetched] <= [_currentFolder totalMessagesCount], @"invalid messageHeadersFetched");
	
	BOOL finishFetch = YES;
	
	if([_currentFolder totalMessagesCount] == [_currentFolder messageHeadersFetched]) {
		NSLog(@"%s: all %llu message headers fetched, stopping", __FUNCTION__, [_currentFolder totalMessagesCount]);
	} else if([_currentFolder messageHeadersFetched] >= MAX_MESSAGE_HEADERS_TO_FETCH) {
		NSLog(@"%s: fetched %llu message headers, stopping", __FUNCTION__, [_currentFolder messageHeadersFetched]);
	} else {
		finishFetch = NO;
	}
	
	if(finishFetch) {
		[[_model messageStorage] endUpdate];
		
		[_fetchMessageHeadersOp cancel];

		_fetchMessageHeadersOp = nil;
		
		[self fetchMessageBodies];
		[self scheduleMessageListUpdate];

		return;
	}

	const uint64_t restOfMessages = [_currentFolder totalMessagesCount] - [_currentFolder messageHeadersFetched];
	const uint64_t numberOfMessagesToFetch = MIN(restOfMessages, MESSAGE_HEADERS_TO_FETCH_AT_ONCE) - 1;
	const uint64_t fetchMessagesFromIndex = restOfMessages - numberOfMessagesToFetch;

//	NSLog(@"%s: fetching messages [%llu ... %llu] for folder '%@'", __FUNCTION__, fetchMessagesFromIndex, fetchMessagesFromIndex + numberOfMessagesToFetch, [folder name]);

	MCOIndexSet *regionToFetch = [MCOIndexSet indexSetWithRange:MCORangeMake(fetchMessagesFromIndex, numberOfMessagesToFetch)];
	
	MCOIMAPSession *session = [ _model session ];
	
	// TODO: handle session reopening/uids validation
	
	NSAssert(session, @"session lost");
	
	MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
	(MCOIMAPMessagesRequestKindHeaders |
	 MCOIMAPMessagesRequestKindStructure |
	 MCOIMAPMessagesRequestKindFullHeaders    |
	 MCOIMAPMessagesRequestKindInternalDate |
	 MCOIMAPMessagesRequestKindHeaderSubject |
	 MCOIMAPMessagesRequestKindFlags |
	 MCOIMAPMessagesRequestKindGmailLabels |
	 MCOIMAPMessagesRequestKindGmailMessageID |
	 MCOIMAPMessagesRequestKindGmailThreadID);
	
	MCOIMAPFetchMessagesOperation *fetchOperation = [session fetchMessagesByNumberOperationWithFolder:[_currentFolder name] requestKind:requestKind numbers:regionToFetch];
	
	_fetchMessageHeadersOp = fetchOperation;

	[fetchOperation start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
		NSAssert(_fetchMessageHeadersOp == fetchOperation, @"message headers fetch ops dont match");
		
		_fetchMessageHeadersOp = nil;
		
		if(error) {
			NSLog(@"Error downloading messages list: %@", error);
		} else {
			_currentFolder.messageHeadersFetched += [messages count];

			[self updateMessageList:messages];
			[self fetchMessageHeaders];
		}
	}];	
}

- (void)updateMessageList:(NSArray*)imapMessages {
//	NSLog(@"%s: new messages count %lu", __FUNCTION__, (unsigned long)[imapMessages count]);

	MCOIMAPSession *session = [_model session];

	[[_model messageStorage] updateIMAPMessages:imapMessages session:session];
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];

	[appController performSelectorOnMainThread:@selector(updateMessageListView) withObject:nil waitUntilDone:NO];

	[_currentFolder.fetchedMessageHeaders addObjectsFromArray:imapMessages];
}

- (void)scheduleMessageListUpdate {
	[self performSelector:@selector(startMessagesUpdate) withObject:nil afterDelay:MESSAGE_LIST_UPDATE_INTERVAL_SEC];
}

- (void)fetchMessageBodies {
//	NSLog(@"%s: fetching message bodies for folder '%@'", __FUNCTION__, [_currentFolder name]);
	
	NSUInteger fetchCount = 0;
	
	for(MCOIMAPMessage *message in _currentFolder.fetchedMessageHeaders) {
		if([self fetchMessageBody:[message uid] threadId:[message gmailThreadID] urgent:NO])
			fetchCount++;
	}

//	NSLog(@"%s: fetching %lu message bodies for folder '%@'", __FUNCTION__, fetchCount, [_currentFolder name]);

	[_currentFolder.fetchedMessageHeaders removeAllObjects];
}

- (BOOL)fetchMessageBody:(uint32_t)uid threadId:(uint64_t)threadId urgent:(BOOL)urgent {
//	NSLog(@"%s: uid %u, threadId %llu, urgent %s", __FUNCTION__, uid, threadId, urgent? "YES" : "NO");

	if([[_model messageStorage] messageHasData:uid threadId:threadId])
		return NO;
		
	MCOIMAPSession *session = [_model session];
	
	NSAssert(session, @"session is nil");
	
	MCOIMAPFetchContentOperation * op = [session fetchMessageByUIDOperationWithFolder:[_currentFolder name] uid:uid urgent:urgent];
	
	// TODO: this op should be stored in the a message property
	// TODO: don't fetch if body is already being fetched (non-urgently!)
	// TODO: if urgent fetch is requested, cancel the non-urgent fetch
	[op start:^(NSError * error, NSData * data) {
		if ([error code] != MCOErrorNone) {
			NSLog(@"Error downloading message body for uid %u", uid);
			return;
		}
		
		NSAssert(data != nil, @"data != nil");
		
//		NSLog(@"%s: msg uid %u", __FUNCTION__, uid);
		
		NSAssert(_model, @"model is disposed");
		
		[[_model messageStorage] setMessageData:data uid:uid threadId:threadId];
		
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

- (void)fetchMessageBodyUrgently:(uint32_t)uid threadId:(uint64_t)threadId {
	[self fetchMessageBody:uid threadId:threadId urgent:YES];
}

@end
