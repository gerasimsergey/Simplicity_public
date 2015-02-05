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

- (Boolean)writeAttachmentTo:(NSURL*)baseUrl {
	return [self writeAttachmentTo:baseUrl withFileName:[self fileName]];
}

- (Boolean)writeAttachmentTo:(NSURL*)baseUrl withFileName:(NSString*)fileName {
	// TODO: write to the message attachments folder
	// TODO: write only if not written yet (compare checksum?)
	// TODO: write asynchronously
	NSString *encodedFileName = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)fileName, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[] ", kCFStringEncodingUTF8);

	NSURL *fullUrl = [NSURL URLWithString:encodedFileName relativeToURL:baseUrl];
	NSData *fileData = [self fileData];
	
	NSError *writeError = nil;
	if(![fileData writeToURL:fullUrl options:NSDataWritingAtomic error:&writeError]) {
		NSLog(@"%s: Could not write file %@: %@", __func__, fullUrl, writeError);
		return FALSE;
	}
	
	NSLog(@"%s: File written: %@", __func__, fullUrl);
	return TRUE;
}

@end
