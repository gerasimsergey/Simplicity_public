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

- (NSData*)fileData {
	MCOAttachment *attachment = _message.attachments[_attachmentIndex];
	NSAssert(attachment != nil, @"bad attachment");
	
	return attachment.data;
}

- (Boolean)writeAttachmentTo:(NSURL*)url {
	return [self writeAttachmentTo:url withFileName:[self fileName]];
}

- (Boolean)writeAttachmentTo:(NSURL*)url withFileName:(NSString*)fileName {
	// TODO: write to the message attachments folder
	// TODO: write only if not written yet (compare checksum?)
	// TODO: write asynchronously
	NSData *fileData = [self fileData];
	
	NSError *writeError = nil;
	if(![fileData writeToURL:[NSURL URLWithString:fileName relativeToURL:url] options:NSDataWritingAtomic error:&writeError]) {
		NSLog(@"%s: Could not write file %@: %@", __func__, url, writeError);
		return FALSE;
	}
	
	NSLog(@"%s: File written: %@", __func__, url);
	return TRUE;
}

@end
