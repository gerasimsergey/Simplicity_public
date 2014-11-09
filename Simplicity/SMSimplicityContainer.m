//
//  SMModel.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/2/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMSimplicityContainer.h"
#import "SMMailbox.h"
#import "SMMessageStorage.h"
#import "SMAttachmentStorage.h"
#import "SMMessageListController.h"
#import "SMSearchResultsListController.h"
#import "SMMailboxController.h"
#import "SMMessageComparators.h"

#import "SMMailLogin.h"

@interface SMSimplicityContainer()

- (void)getIMAPServerCapabilities;

@end

@implementation SMSimplicityContainer {
	MCOIMAPCapabilityOperation *_capabilitiesOp;
}

@synthesize imapServerCapabilities = _imapServerCapabilities;

- (id)init {
	self = [ super init ];
	
	if(self) {
//		MCLogEnabled = 1;
		
		_session = [[MCOIMAPSession alloc] init];
		
		[_session setPort:993];
		
		[_session setHostname:MAIL_SERVER_HOSTNAME];
		[_session setUsername:MAIL_USERNAME];
		[_session setPassword:MAIL_PASSWORD];
		
		[_session setConnectionType:MCOConnectionTypeTLS];
		
		_mailbox = [ SMMailbox new ];
		_messageStorage = [ SMMessageStorage new ];
		_attachmentStorage = [ SMAttachmentStorage new ];
		
		_messageListController = [[ SMMessageListController alloc ] initWithModel:self ];
		_searchResultsListController = [[SMSearchResultsListController alloc] init];
		_mailboxController = [[ SMMailboxController alloc ] initWithModel:self ];
		_messageComparators = [SMMessageComparators new];

		[self getIMAPServerCapabilities];
	}
	
	NSLog(@"%s: model initialized", __FUNCTION__);
		  
	return self;
}

- (void)startSession {
	[_mailboxController updateFolders];
	[_messageListController changeFolder:@"INBOX"];
}

- (MCOIndexSet*)imapServerCapabilities {
	MCOIndexSet *capabilities = _imapServerCapabilities;

	NSLog(@"%s: IMAP server capabilities: %@", __FUNCTION__, capabilities);
	
	return capabilities;
}

- (void)getIMAPServerCapabilities {
	NSAssert(_capabilitiesOp == nil, @"_capabilitiesOp is not nil");
		
	_capabilitiesOp = [_session capabilityOperation];

	[_capabilitiesOp start:^(NSError * error, MCOIndexSet * capabilities) {
		if(error) {
			NSLog(@"%s: error getting IMAP capabilities: %@", __FUNCTION__, error);
		} else {
			NSLog(@"%s: capabilities: %@", __FUNCTION__, capabilities);
		
			_imapServerCapabilities = capabilities;
		}
	}];
}

@end
