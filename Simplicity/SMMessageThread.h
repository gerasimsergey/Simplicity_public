//
//  SMMessageThread.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/14/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCOIMAPMessage;
@class MCOIMAPSession;
@class SMMessage;

@interface SMMessageThread : NSObject

- (id)initWithThreadId:(uint64_t)threadId;

- (uint64_t)threadId;
- (SMMessage*)latestMessage;

- (NSInteger)messagesCount;
- (NSArray*)messagesSortedByDate;
- (SMMessage*)getMessage:(uint32_t)uid;

- (void)updateIMAPMessage:(MCOIMAPMessage*)imapMessage folder:(NSString*)folder session:(MCOIMAPSession*)session;
- (void)endUpdate;
- (void)cancelUpdate;

- (void)setMessageData:(NSData*)data uid:(uint32_t)uid;
- (BOOL)messageHasData:(uint32_t)uid;

@end
