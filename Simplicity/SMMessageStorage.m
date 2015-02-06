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

- (NSUInteger)getMessageThreadIndexByDate:(SMMessageThread*)messageThread localFolder:(NSString*)localFolder {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");
		
	NSMutableOrderedSet *sortedMessageThreads = collection.messageThreadsByDate;
	NSComparator messageThreadComparator = [comparators messageThreadsComparatorByDate];

	if([collection.messageThreads objectForKey:[NSNumber numberWithLongLong:[messageThread threadId]]] != nil) {
		return [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:0 usingComparator:messageThreadComparator];
	} else {
		return NSNotFound;
	}
}

- (void)insertMessageThreadByDate:(SMMessageThread*)messageThread localFolder:(NSString*)localFolder oldIndex:(NSUInteger)oldIndex {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");

	NSMutableOrderedSet *sortedMessageThreads = collection.messageThreadsByDate;
	NSComparator messageThreadComparator = [comparators messageThreadsComparatorByDate];

	if(oldIndex != NSUIntegerMax)
		[sortedMessageThreads removeObjectAtIndex:oldIndex];
	
	NSUInteger messageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:NSBinarySearchingInsertionIndex usingComparator:messageThreadComparator];
	
	NSAssert(messageThreadIndexByDate != NSNotFound, @"message thread not found");
	
	[sortedMessageThreads insertObject:messageThread atIndex:messageThreadIndexByDate];

	//TODO: remove/leave in debug mode only
/*
	//NSLog(@"validate threads");
	SMMessageThread *p = nil;
	for(id i in sortedMessageThreads) {
		SMMessageThread *t = i;
		//SMMessage *pi = t.messagesSortedByDate.firstObject;
		//NSLog(@"threadId %llu, date %@", t.threadId, pi.date);
		if(p != nil) {
			SMMessage *m = t.messagesSortedByDate.firstObject;
			SMMessage *pm = p.messagesSortedByDate.firstObject;
			NSComparisonResult r = [pm.date compare:m.date];
			NSAssert(r != NSOrderedAscending, @"threads not sorted");
		}
		p = i;
	}
*/
}

- (void)startUpdate:(NSString*)localFolder {
	//	NSLog(@"%s: localFolder '%@'", __FUNCTION__, localFolder);
	
	[self cancelUpdate:localFolder];
}

- (SMMessageStorageUpdateResult)updateIMAPMessages:(NSArray*)imapMessages localFolder:(NSString*)localFolder remoteFolder:(NSString*)remoteFolder session:(MCOIMAPSession*)session {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad folder collection");
	
	SMMessageStorageUpdateResult updateResult = SMMesssageStorageUpdateResultNone;
	
	for(MCOIMAPMessage *imapMessage in imapMessages) {
		//NSLog(@"%s: looking for imap message with uid %u, gmailThreadId %llu", __FUNCTION__, [imapMessage uid], [imapMessage gmailThreadID]);

		const uint64_t threadId = [imapMessage gmailThreadID];
		NSNumber *threadIdKey = [NSNumber numberWithUnsignedLongLong:threadId];
		SMMessageThread *messageThread = [[collection messageThreads] objectForKey:threadIdKey];

		NSDate *firstMessageDate = nil;
		NSUInteger oldIndex = NSUIntegerMax;
		
		Boolean threadUpdated = NO;

		if(messageThread == nil) {
			messageThread = [[SMMessageThread alloc] initWithThreadId:threadId];
			[[collection messageThreads] setObject:messageThread forKey:threadIdKey];
			
			threadUpdated = YES;
		} else {
			oldIndex = [self getMessageThreadIndexByDate:messageThread localFolder:localFolder];
			NSAssert(oldIndex != NSNotFound, @"message thread not found");
			
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;
			firstMessageDate = [firstMessage date];
		}

		SMThreadUpdateResult threadUpdateResult = [messageThread updateIMAPMessage:imapMessage remoteFolder:remoteFolder session:session];
		if(threadUpdateResult != SMThreadUpdateResultNone) {
			if(updateResult == SMMesssageStorageUpdateResultNone) {
				updateResult = (threadUpdateResult == SMThreadUpdateResultStructureChanged? SMMesssageStorageUpdateResultStructureChanged : SMMesssageStorageUpdateResultFlagsChanged);
			} else if(updateResult == SMThreadUpdateResultStructureChanged) {
				updateResult = SMMesssageStorageUpdateResultStructureChanged;
			}
		}

		if(!threadUpdated) {
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;

			if(firstMessageDate != [firstMessage date])
				threadUpdated = YES;
		}
		
		if(threadUpdated) {
			[self insertMessageThreadByDate:messageThread localFolder:localFolder oldIndex:oldIndex];
			updateResult = SMMesssageStorageUpdateResultStructureChanged;
		}

		NSAssert(collection.messageThreads.count == collection.messageThreadsByDate.count, @"message threads count %lu not equal to sorted threads count %lu (oldIndex %lu, threadUpdated %u, threadUpdateResult %lu)", collection.messageThreads.count, collection.messageThreadsByDate.count, oldIndex, threadUpdated, threadUpdateResult);
	}
	
	return updateResult;
}

- (SMMessageStorageUpdateResult)endUpdate:(NSString*)localFolder removeVanishedMessages:(Boolean)removeVanishedMessages {
//	NSLog(@"%s: localFolder '%@'", __FUNCTION__, localFolder);
	
	SMMessageStorageUpdateResult updateResult = SMMesssageStorageUpdateResultNone;
	
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad thread collection");
	
	NSMutableSet *vanishedThreadIds = [[NSMutableSet alloc] init];

	for(NSNumber *threadId in collection.messageThreads) {
		SMMessageThread *messageThread = [collection.messageThreads objectForKey:threadId];
		NSUInteger oldIndex = [self getMessageThreadIndexByDate:messageThread localFolder:localFolder];

		SMThreadUpdateResult threadUpdateResult = [messageThread endUpdate:removeVanishedMessages];

		if(threadUpdateResult == SMThreadUpdateResultStructureChanged) {
			if([messageThread messagesCount] == 0) {
				NSLog(@"%s: message thread %lld vanished", __func__, messageThread.threadId);

				[vanishedThreadIds addObject:[NSNumber numberWithUnsignedLongLong:[messageThread threadId]]];
				[collection.messageThreadsByDate removeObject:messageThread];
			} else {
				NSAssert(oldIndex != NSNotFound, @"message thread not found");
				[self insertMessageThreadByDate:messageThread localFolder:localFolder oldIndex:oldIndex];
			}
			
			updateResult = SMMesssageStorageUpdateResultStructureChanged;
		} else if(threadUpdateResult == SMThreadUpdateResultFlagsChanged && updateResult == SMThreadUpdateResultNone) {
			updateResult = SMMesssageStorageUpdateResultFlagsChanged;
		}
	}

	[collection.messageThreads removeObjectsForKeys:[vanishedThreadIds allObjects]];

	NSAssert(collection.messageThreads.count == collection.messageThreadsByDate.count, @"message threads count %lu not equal to sorted threads count %lu", collection.messageThreads.count, collection.messageThreadsByDate.count);
	
	return updateResult;
}

- (void)cancelUpdate:(NSString*)localFolder {
	MessageThreadCollection *collection = [self messageThreadForFolder:localFolder];
	NSAssert(collection, @"bad thread collection");
	
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
	SMMessageThread *thread = [self messageThreadById:threadId localFolder:localFolder];
	NSAssert(thread != nil, @"thread id %lld not found in local folder %@", threadId, localFolder);

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

- (SMMessageThread*)messageThreadById:(uint64_t)threadId localFolder:(NSString*)folder {
	MessageThreadCollection *collection = [self messageThreadForFolder:folder];

	if(collection == nil)
		return nil;

	return [collection.messageThreads objectForKey:[NSNumber numberWithLongLong:threadId]];
}

@end
