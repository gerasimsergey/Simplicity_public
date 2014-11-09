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

@implementation SMLocalFolder

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

	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];

	if([[[appDelegate model] messageStorage] messageHasData:uid localFolder:_name threadId:threadId])
		return NO;
	
	MCOIMAPSession *session = [[appDelegate model] session];
	
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

		//	NSLog(@"%s: msg uid %u", __FUNCTION__, uid);
		
		[[[appDelegate model] messageStorage] setMessageData:data uid:uid localFolder:_name threadId:threadId];
		
		NSDictionary *messageInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:uid], [NSNumber numberWithUnsignedLongLong:threadId], nil] forKeys:[NSArray arrayWithObjects:@"UID", @"ThreadId", nil]];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageBodyFetched" object:nil userInfo:messageInfo];
	}];
	
	return YES;
}

@end
