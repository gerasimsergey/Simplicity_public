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
#import "SMMessageEditorWindowController.h"

@implementation SMMessageEditorWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
	[_messageTextEditor setFrameLoadDelegate:self];
	[_messageTextEditor setPolicyDelegate:self];
	[_messageTextEditor setResourceLoadDelegate:self];
	[_messageTextEditor setCanDrawConcurrently:YES];
	[_messageTextEditor setEditable:YES];
	
	[_toField setDelegate:self];
	
	[_sendButton setEnabled:NO];
}

- (void)windowWillClose:(NSNotification *)notification {
	NSLog(@"%s", __func__);

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[appController closeMessageEditorWindow:self];
}

#pragma mark Actions

- (IBAction)sendAction:(id)sender {
	NSData *messageData = [self createMessageData];

	NSLog(@"%s: '%@'", __func__, messageData);
}

- (IBAction)saveAction:(id)sender {
	NSLog(@"%s", __func__);
}

- (IBAction)attachAction:(id)sender {
	NSLog(@"%s", __func__);
}

#pragma mark UI controls collaboration

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	if(control == _toField) {
		NSString *toValue = [[_toField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t"]];

		NSLog(@"%s: to field ends editing, string value '%@'", __func__, toValue);
		
		[_sendButton setEnabled:(toValue.length != 0)];
	}
	
	return YES;
}

#pragma mark Message creation

- (NSData*)createMessageData {
	MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];

	//TODO (custom from): [[builder header] setFrom:[MCOAddress addressWithDisplayName:@"Hoa V. DINH" mailbox:@"hoa@etpan.org"]];

	// TODO: form an array of addresses and names based on _toField contents
	NSArray *toAddresses = [NSArray arrayWithObject:[MCOAddress addressWithDisplayName:@"TODO" mailbox:_toField.stringValue]];
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
	//TODO (send plain text): 	[(DOMHTMLElement *)[[[webView mainFrame] DOMDocument] documentElement] outerText];

	[builder setHTMLBody:messageText];

	//TODO (local attachments): [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:@"/Users/foo/Pictures/image.jpg"]];

	NSData *rfc822Data = [builder data];
	return rfc822Data;
}

@end
