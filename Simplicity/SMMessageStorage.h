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

- (void)ensureFolderExists:(NSString*)folder;

- (NSInteger)messageThreadsCount:(NSString*)folder;

- (void)startUpdate:(NSString*)folder;
- (void)updateIMAPMessages:(NSArray*)imapMessages threadFolder:(NSString*)threadFolder messagesFolder:(NSString*)messagesFolder session:(MCOIMAPSession*)session;
- (void)endUpdate:(NSString*)folder;

- (SMMessageThread*)messageThreadAtIndexByDate:(NSString*)folder index:(NSUInteger)index;

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid folder:(NSString*)folder threadId:(uint64_t)threadId;
- (BOOL)messageHasData:(uint32_t)uid folder:(NSString*)folder threadId:(uint64_t)threadId;

@end
