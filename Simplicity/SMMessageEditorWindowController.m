//
//  SMMessageEditorWindowController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/25/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <WebKit/WebView.h>

#import <MailCore/MailCore.h>

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMTokenField.h"
#import "SMOutboxController.h"
#import "SMLabeledTokenFieldBoxViewController.h"
#import "SMMessageEditorWindowController.h"

#import "SMMailLogin.h"

@implementation SMMessageEditorWindowController

- (void)awakeFromNib {
	NSLog(@"%s", __func__);

	_toBoxViewController = [[SMLabeledTokenFieldBoxViewController alloc] initWithNibName:@"SMLabeledTokenFieldBoxViewController" bundle:nil];

	[_toBoxView addSubview:_toBoxViewController.view];

	[_toBoxView addConstraint:[NSLayoutConstraint constraintWithItem:_toBoxView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_toBoxViewController.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
	
	[_toBoxView addConstraint:[NSLayoutConstraint constraintWithItem:_toBoxView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_toBoxViewController.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];

	[_toBoxView addConstraint:[NSLayoutConstraint constraintWithItem:_toBoxView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_toBoxViewController.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];

	[_toBoxView addConstraint:[NSLayoutConstraint constraintWithItem:_toBoxView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toBoxViewController.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
	[_messageTextEditor setFrameLoadDelegate:self];
	[_messageTextEditor setPolicyDelegate:self];
	[_messageTextEditor setResourceLoadDelegate:self];
	[_messageTextEditor setCanDrawConcurrently:YES];
	[_messageTextEditor setEditable:YES];
	
	[_sendButton setEnabled:NO];
}

- (void)windowWillClose:(NSNotification *)notification {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[appController closeMessageEditorWindow:self];
}

#pragma mark Actions

- (IBAction)sendAction:(id)sender {
	MCOMessageBuilder *message = [self createMessageData];

	NSLog(@"%s: '%@'", __func__, message);

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[[appController outboxController] sendMessage:message];
	
	[self close];
}

- (IBAction)saveAction:(id)sender {
	NSLog(@"%s", __func__);
}

- (IBAction)attachAction:(id)sender {
	NSLog(@"%s", __func__);
}

#pragma mark UI controls collaboration

/*TODO
 - (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	if(control == _toBoxViewController.label) {
		NSString *toValue = [[_toField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t"]];

		NSLog(@"%s: to field ends editing, string value '%@'", __func__, toValue);
		
		[_sendButton setEnabled:(toValue.length != 0)];
	}
	
	return YES;
}
*/

#pragma mark Message creation

- (MCOMessageBuilder*)createMessageData {
	MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];

	//TODO: custom from
	[[builder header] setFrom:[MCOAddress addressWithDisplayName:@"Evgeny Baskakov" mailbox:SMTP_USERNAME]];

	// TODO: form an array of addresses and names based on _toField contents
	NSArray *toAddresses = [NSArray arrayWithObject:[MCOAddress addressWithDisplayName:@"TODO" mailbox:_toBoxViewController.tokenField.stringValue]];
	[[builder header] setTo:toAddresses];

	// TODO: form an array of addresses and names based on _ccField contents
	NSArray *ccAddresses = [NSArray arrayWithObject:[MCOAddress addressWithDisplayName:@"TODO" mailbox:_ccField.stringValue]];
	[[builder header] setCc:ccAddresses];
	
	// TODO: form an array of addresses and names based on _bccField contents
	NSArray *bccAddresses = [NSArray arrayWithObject:[MCOAddress addressWithDisplayName:@"TODO" mailbox:_bccField.stringValue]];
	[[builder header] setBcc:bccAddresses];

	// TODO: check subject length, issue a warning if empty
	[[builder header] setSubject:_subjectField.stringValue];

	NSString *messageText = [(DOMHTMLElement *)[[[_messageTextEditor mainFrame] DOMDocument] documentElement] outerHTML];
	//TODO (send plain text): [(DOMHTMLElement *)[[[webView mainFrame] DOMDocument] documentElement] outerText];

	[builder setHTMLBody:messageText];

	//TODO (local attachments): [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:@"/Users/foo/Pictures/image.jpg"]];

	return builder;
}

@end
