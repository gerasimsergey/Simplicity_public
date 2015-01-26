//
//  SMAttachmentItem.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMMessage.h"
#import "SMAttachmentItem.h"

@implementation SMAttachmentItem {
	SMMessage *_message;
	NSUInteger _attachmentIndex;
}

- (id)initWithMessage:(SMMessage*)message attachmentIndex:(NSUInteger)attachmentIndex {
	NSAssert(message != nil, @"message is nil");
	NSAssert(message.attachments != nil, @"message has not attachments");
	NSAssert(attachmentIndex < message.attachments.count, @"attachment index is out of bounds");

	self = [super init];
	
	if(self) {
		_message = message;
		_attachmentIndex = attachmentIndex;
	}

	return self;
}

- (NSString*)fileName {
	MCOAttachment *attachment = _message.attachments[_attachmentIndex];
	NSAssert(attachment != nil, @"bad attachment");

	return attachment.filename;
}

@end
