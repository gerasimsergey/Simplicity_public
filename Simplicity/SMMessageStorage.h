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

- (NSInteger)messageThreadsCount;

- (void)startUpdate;
- (void)updateIMAPMessages:(NSArray*)imapMessages session:(MCOIMAPSession*)session;
- (void)endUpdate;

- (SMMessageThread*)messageThreadAtIndexByDate:(NSUInteger)index;

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid threadId:(uint64_t)threadId;
- (BOOL)messageHasData:(uint32_t)uid threadId:(uint64_t)threadId;

- (void)switchFolder:(NSString*)folderName;

@end
