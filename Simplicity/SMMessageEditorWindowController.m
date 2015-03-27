//
//  SMMessageEditorWindowController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/25/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <WebKit/WebView.h>

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
}

- (void)windowWillClose:(NSNotification *)notification {
	NSLog(@"%s", __func__);

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[appController closeMessageEditorWindow:self];
}

- (IBAction)sendAction:(id)sender {
	NSLog(@"%s", __func__);
}

- (IBAction)saveAction:(id)sender {
	NSLog(@"%s", __func__);
}

- (IBAction)attachAction:(id)sender {
	NSLog(@"%s", __func__);
}

@end
