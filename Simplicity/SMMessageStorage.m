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

- (void)ensureLocalFolderExists:(NSString*)localFolder {
	NSLog(@"%s: folder name '%@", __FUNCTION__, localFolder);
	
	MessageThreadCollection *collection = [_foldersMessageThreadsMap objectForKey:localFolder];
	
	if(collection == nil)
		[_foldersMessageThreadsMap setValue:[MessageThreadCollection new] forKey:localFolder];
}

- (void)removeLocalFolder:(NSString*)localFolder {
	[_foldersMessageThreadsMap removeObjectForKey:localFolder];
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

		Boolean updateThread = NO;
		NSDate *firstMessageDate = nil;
		NSUInteger oldMessageThreadIndexByDate = 0;
		
		if(messageThread == nil) {
			messageThread = [[SMMessageThread alloc] initWithThreadId:threadId];
			[[collection messageThreads] setObject:messageThread forKey:threadIdKey];
			
			updateThread = YES;
		} else {
			oldMessageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:0 usingComparator:messageThreadComparator];

			NSAssert(oldMessageThreadIndexByDate != NSNotFound, @"message thread not found");
			
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;
			firstMessageDate = [firstMessage date];
		}

		[messageThread updateIMAPMessage:imapMessage remoteFolder:remoteFolder session:session];

		if(!updateThread) {
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;

			if(firstMessageDate != [firstMessage date]) {
				[sortedMessageThreads removeObjectAtIndex:oldMessageThreadIndexByDate];
				updateThread = YES;
			}
		}
		
		if(updateThread) {
			NSUInteger messageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:NSBinarySearchingInsertionIndex usingComparator:messageThreadComparator];
			
			[sortedMessageThreads insertObject:messageThread atIndex:messageThreadIndexByDate];

#if 0
			NSLog(@"validate threads");
			SMMessageThread *p = nil;
			for(id i in sortedMessageThreads) {
				SMMessageThread *t = i;
				SMMessage *pi = t.messagesSortedByDate.firstObject;
				NSLog(@"threadId %llu, date %@", t.threadId, pi.date);
				if(p != nil) {
					SMMessage *m = t.messagesSortedByDate.firstObject;
					SMMessage *pm = p.messagesSortedByDate.firstObject;
					NSComparisonResult r = [pm.date compare:m.date];
					NSAssert(r != NSOrderedAscending, @"threads not sorted");
				}
				p = i;
			}
#endif
		}

		NSAssert(collection.messageThreads.count == collection.messageThreadsByDate.count, @"message threads count not equal to sorted threads count");
	}
}

- (void)startUpdate:(NSString*)folder {
	NSLog(@"%s: folder '%@'", __FUNCTION__, folder);

	[self cancelUpdate:folder];
}

- (void)endUpdate:(NSString*)folder removeVanishedMessages:(Boolean)removeVanishedMessages {
	NSLog(@"%s: folder '%@'", __FUNCTION__, folder);
	
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];
	NSAssert(collection, @"bad folder collection");
	
	NSMutableSet *vanishedThreads = [[NSMutableSet alloc] init];
	NSMutableSet *vanishedThreadIds = [[NSMutableSet alloc] init];

	for(NSNumber *threadId in collection.messageThreads) {
		SMMessageThread *thread = [collection.messageThreads objectForKey:threadId];
		[thread endUpdate:removeVanishedMessages];
		
		if([thread messagesCount] == 0) {
			[vanishedThreads addObject:thread];
			[vanishedThreadIds addObject:[NSNumber numberWithUnsignedLongLong:[thread threadId]]];
		}
	}

	[collection.messageThreads removeObjectsForKeys:[vanishedThreadIds allObjects]];
	[collection.messageThreadsByDate removeObjectsInArray:[vanishedThreads allObjects]];

	NSAssert(collection.messageThreads.count == collection.messageThreadsByDate.count, @"message threads count not equal to sorted threads count");
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

- (NSInteger)messageThreadsCountInLocalFolder:(NSString*)localFolder {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];

	// usually this means that no folders loaded yet
	if(collection == nil)
		return 0;

	return [collection.messageThreads count];
}

- (SMMessageThread*)messageThreadAtIndexByDate:(NSUInteger)index localFolder:(NSString*)folder {
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];
	
	NSAssert(collection, @"no thread collection found");
	
	if(index >= [collection.messageThreadsByDate count]) {
		NSLog(@"%s: index %lu is beyond message thread size %lu", __func__, index, [collection.messageThreadsByDate count]);
		return nil;
	}

	return [collection.messageThreadsByDate objectAtIndex:index];
}

@end
