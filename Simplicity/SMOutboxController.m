//
//  SMOutboxController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/26/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMAppDelegate.h"
#import "SMOutboxController.h"

@implementation SMOutboxController

- (void)sendMessage:(MCOMessageBuilder*)message {
	NSLog(@"%s", __func__);

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

	MCOSMTPOperation *op = [[[appDelegate model] smtpSession] sendOperationWithData:message.data];

	[op start:^(NSError * error) {
		if (error != nil && [error code] != MCOErrorNone) {
			NSLog(@"%s: Error sending message: %@", __func__, error);
			return;
		}

		NSLog(@"%s: message sent successfully", __func__);
	}];
}

@end
