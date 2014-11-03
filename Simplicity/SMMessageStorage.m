 //
//  SM_messagestorage.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/2/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMMessage.h"
#import "SMMessageComparators.h"
#import "SMMessageStorage.h"
#import "SMMessageThread.h"
#import "SMAppDelegate.h"

@interface MessageThreadCollection : NSObject
@property NSMutableDictionary *messageThreads;
@property NSMutableOrderedSet *messageThreadsByDate;
@end

@implementation MessageThreadCollection

- (id)init {
	self = [ super init ];
	
	if(self) {
		_messageThreads = [ NSMutableDictionary new ];
		_messageThreadsByDate = [ NSMutableOrderedSet new ];
	}
	
	return self;
}

@end

@implementation SMMessageStorage {
@private
	// keeps a collection of message threads for each folder
	NSMutableDictionary *_foldersMessageThreadsMap;
}

@synthesize comparators;

- (id)init {
	self = [ super init ];

	if(self) {
		comparators = [SMMessageComparators new];
		
		_foldersMessageThreadsMap = [NSMutableDictionary new];
	}

	return self;
}

- (void)ensureFolderExists:(NSString*)folder {
	NSLog(@"%s: folder name '%@", __FUNCTION__, folder);
	
	MessageThreadCollection *collection = [_foldersMessageThreadsMap objectForKey:folder];
	
	if(collection == nil)
		[_foldersMessageThreadsMap setValue:[MessageThreadCollection new] forKey:folder];
}

- (MessageThreadCollection*)messageThreadForFolder:(NSString*)folder {
	return [_foldersMessageThreadsMap objectForKey:folder];
}

- (void)updateIMAPMessages:(NSArray*)imapMessages localFolder:(NSString*)localFolder remoteFolder:(NSString*)remoteFolder session:(MCOIMAPSession*)session {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");
	
	NSMutableOrderedSet *sortedMessageThreads = collection.messageThreadsByDate;
	NSComparator messageThreadComparator = [comparators messageThreadsComparatorByDate];
	
	for(MCOIMAPMessage *imapMessage in imapMessages) {
		//NSLog(@"%s: looking for imap message with uid %u, gmailThreadId %llu", __FUNCTION__, [imapMessage uid], [imapMessage gmailThreadID]);
		
		const uint64_t threadId = [imapMessage gmailThreadID];
		NSNumber *threadIdKey = [NSNumber numberWithUnsignedLongLong:threadId];
		SMMessageThread *messageThread = [[collection messageThreads] objectForKey:threadIdKey];

		Boolean newThread = false;
		NSDate *firstMessageDate = nil;
		NSUInteger oldMessageThreadIndexByDate = 0;
		
		if(messageThread == nil) {
			messageThread = [[SMMessageThread alloc] initWithThreadId:threadId];
			[[collection messageThreads] setObject:messageThread forKey:threadIdKey];
			
			newThread = true;
		} else {
			oldMessageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:0 usingComparator:messageThreadComparator];
			
			NSAssert(oldMessageThreadIndexByDate != NSNotFound, @"message thread not found");
			
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;

			firstMessageDate = [firstMessage date];
		}

		[messageThread updateIMAPMessage:imapMessage remoteFolder:remoteFolder session:session];

		Boolean doInsertion = true;
		
		if(!newThread) {
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;

			if(firstMessageDate != [firstMessage date])
				[sortedMessageThreads removeObjectAtIndex:oldMessageThreadIndexByDate];
			else
				doInsertion = false;
		}
		
		if(doInsertion) {
			NSUInteger messageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:NSBinarySearchingInsertionIndex usingComparator:messageThreadComparator];
			
			[sortedMessageThreads insertObject:messageThread atIndex:messageThreadIndexByDate];
		}
	}
}

- (void)startUpdate:(NSString*)folder {
	NSLog(@"%s: folder '%@'", __FUNCTION__, folder);

	[self cancelUpdate:folder];
}

- (void)endUpdate:(NSString*)folder {
	NSLog(@"%s: folder '%@'", __FUNCTION__, folder);
	
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];
	NSAssert(collection, @"bad folder collection");
	
	NSMutableSet *vanishedThreads = [NSMutableSet new];

	for(NSNumber *threadId in collection.messageThreads) {
		SMMessageThread *thread = [collection.messageThreads objectForKey:threadId];
		[thread endUpdate];
		
		if([thread messagesCount] == 0)
			[vanishedThreads addObject:thread];
	}

	[collection.messageThreads removeObjectsForKeys:[vanishedThreads allObjects]];
	[collection.messageThreadsByDate removeObjectsInArray:[vanishedThreads allObjects]];
}

- (void)cancelUpdate:(NSString*)folder {
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];
	NSAssert(collection, @"bad folder collection");
	
	for(NSNumber *threadId in collection.messageThreads) {
		SMMessageThread *thread = [collection.messageThreads objectForKey:threadId];
		[thread cancelUpdate];
	}
}

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid localFolder:(NSString*)localFolder threadId:(uint64_t)threadId {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");
	
	SMMessageThread *thread = [collection.messageThreads objectForKey:[NSNumber numberWithLongLong:threadId]];
	[thread setMessageData:data uid:uid];
}

- (BOOL)messageHasData:(uint32_t)uid localFolder:(NSString*)localFolder threadId:(uint64_t)threadId {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");

	SMMessageThread *thread = [collection.messageThreads objectForKey:[NSNumber numberWithLongLong:threadId]];
	return [thread messageHasData:uid];
}

- (NSInteger)messageThreadsCount:(NSString*)folder {
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];

	// usually this means that no folders loaded yet
	if(collection == nil)
		return 0;

	return [collection.messageThreads count];
}

- (SMMessageThread*)messageThreadAtIndexByDate:(NSUInteger)index localFolder:(NSString*)folder {
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];
	
	NSAssert(collection, @"no thread collection found");
	
	if(index >= [collection.messageThreadsByDate count]) {
		// TODO!!!
		NSLog(@"%s: message index %lu >= message thread message count %lu", __func__, index, [collection.messageThreadsByDate count]);
	}
	
	NSAssert(index < [collection.messageThreadsByDate count], @"bad index");

	return [collection.messageThreadsByDate objectAtIndex:index];
}

@end
