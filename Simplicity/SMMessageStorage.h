//
//  SMMessageStorage.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/2/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MailCore/MailCore.h>

@class SMMessage;
@class SMMessageComparators;
@class SMMessageThread;

@interface SMMessageStorage : NSObject

@property (readonly) SMMessageComparators *comparators;

- (void)ensureLocalFolderExists:(NSString*)localFolder;
- (void)removeLocalFolder:(NSString*)localFolder;

- (NSInteger)messageThreadsCountInLocalFolder:(NSString*)localFolder;

- (void)startUpdate:(NSString*)folder;
- (void)updateIMAPMessages:(NSArray*)imapMessages localFolder:(NSString*)localFolder remoteFolder:(NSString*)remoteFolder session:(MCOIMAPSession*)session;
- (void)endUpdate:(NSString*)folder removeVanishedMessages:(Boolean)removeVanishedMessages;

- (SMMessageThread*)messageThreadById:(uint64_t)threadId localFolder:(NSString*)folder;
- (SMMessageThread*)messageThreadAtIndexByDate:(NSUInteger)index localFolder:(NSString*)folder;
- (NSUInteger)getMessageThreadIndex:(SMMessageThread*)messageThread localFolder:(NSString*)localFolder;

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid localFolder:(NSString*)localFolder threadId:(uint64_t)threadId;
- (BOOL)messageHasData:(uint32_t)uid localFolder:(NSString*)localFolder threadId:(uint64_t)threadId;

@end
