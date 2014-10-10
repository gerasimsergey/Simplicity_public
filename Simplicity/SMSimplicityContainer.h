//
//  SMModel.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/2/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MailCore/MailCore.h>

@class SMMailbox;
@class SMMessageStorage;
@class SMAttachmentStorage;
@class SMMessageListController;
@class SMMailboxController;
@class SMMessageComparators;

@class MCOIMAPSession;

@interface SMSimplicityContainer : NSObject

@property MCOIMAPSession *session;
@property (readonly) SMMessageStorage *messageStorage;
@property (readonly) SMAttachmentStorage *attachmentStorage;
@property (readonly) MCOIndexSet *imapServerCapabilities;
@property (readonly) SMMessageListController *messageListController;
@property (readonly) SMMailboxController *mailboxController;
@property (readonly) SMMailbox *mailbox;
@property (readonly) SMMessageComparators *messageComparators;

- (void)startSession;

@end
