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

@interface SMMessageStorage()

- (void)cancelUpdate;

@end

@implementation SMMessageStorage {
@private
	NSMutableDictionary *_foldersMessageThreadsMap;
	NSString *_currentFolder;
	
	BOOL _updating;
}

@synthesize comparators;

- (id)init {
	self = [ super init ];

	if(self) {
		comparators = [SMMessageComparators new];
		
		_foldersMessageThreadsMap = [NSMutableDictionary new];
		_currentFolder = @"";
		_updating = NO;
		
		[self switchFolder:_currentFolder];
	}

	return self;
}

- (void)switchFolder:(NSString*)folderName {
	NSLog(@"%s: folder name '%@", __FUNCTION__, folderName);
	
	MessageThreadCollection *collection = [_foldersMessageThreadsMap objectForKey:folderName];
	
	if(collection == nil)
		[_foldersMessageThreadsMap setValue:[MessageThreadCollection new] forKey:folderName];
	
 	_currentFolder = folderName;
}

- (MessageThreadCollection*)getCurrentFolderMessageThread {
	return [_foldersMessageThreadsMap objectForKey:_currentFolder];
}

- (void)updateIMAPMessages:(NSArray*)imapMessages session:(MCOIMAPSession*)session {
	NSAssert(_updating, @"no update in process");
	
	MessageThreadCollection *collection = [self getCurrentFolderMessageThread];
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
			messageThread = [[SMMessageThread alloc] initWithThreadId:threadId folder:_currentFolder];
			[[collection messageThreads] setObject:messageThread forKey:threadIdKey];
			
			newThread = true;
		} else {
			oldMessageThreadIndexByDate = [sortedMessageThreads indexOfObject:messageThread inSortedRange:NSMakeRange(0, sortedMessageThreads.count) options:0 usingComparator:messageThreadComparator];
			
			NSAssert(oldMessageThreadIndexByDate != NSNotFound, @"message thread not found");
			
			SMMessage *firstMessage = messageThread.messagesSortedByDate.firstObject;

			firstMessageDate = [firstMessage date];
		}

		[messageThread updateIMAPMessage:imapMessage session:session];

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

- (void)startUpdate {
	NSLog(@"%s: current folder '%@'", __FUNCTION__, _currentFolder);

	[self cancelUpdate];

	_updating = YES;
}

- (void)endUpdate {
	NSLog(@"%s: current folder '%@'", __FUNCTION__, _currentFolder);
	
	MessageThreadCollection *collection = [self getCurrentFolderMessageThread];
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

	_updating = NO;
}

- (void)cancelUpdate {
	MessageThreadCollection *collection = [self getCurrentFolderMessageThread];
	NSAssert(collection, @"bad folder collection");
	
	if(!_updating) {
		NSLog(@"no updating is in process");
		return;
	}

	for(NSNumber *threadId in collection.messageThreads) {
		SMMessageThread *thread = [collection.messageThreads objectForKey:threadId];
		[thread cancelUpdate];
	}
	
	_updating = NO;
}

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid threadId:(uint64_t)threadId {
	MessageThreadCollection *collection = [self getCurrentFolderMessageThread];
	NSAssert(collection, @"bad folder collection");
	
	SMMessageThread *thread = [collection.messageThreads objectForKey:[NSNumber numberWithLongLong:threadId]];
	[thread setMessageData:data uid:uid];
}

- (BOOL)messageHasData:(uint32_t)uid threadId:(uint64_t)threadId {
	MessageThreadCollection *collection = [self getCurrentFolderMessageThread];
	NSAssert(collection, @"bad folder collection");

	SMMessageThread *thread = [collection.messageThreads objectForKey:[NSNumber numberWithLongLong:threadId]];
	return [thread messageHasData:uid];
}

- (NSInteger)messageThreadsCount {
	MessageThreadCollection *collection = [_foldersMessageThreadsMap objectForKey:_currentFolder];

	NSAssert(collection, @"no thread collection for current folder");
	return [collection.messageThreads count];
}

- (SMMessageThread*)messageThreadAtIndexByDate:(NSUInteger)index {
	MessageThreadCollection *collection = [_foldersMessageThreadsMap objectForKey:_currentFolder];
	
	NSAssert(collection, @"no thread collection for current folder");
	NSAssert(index < [collection.messageThreadsByDate count], @"bad index");
	
	return [collection.messageThreadsByDate objectAtIndex:index];
}

@end
