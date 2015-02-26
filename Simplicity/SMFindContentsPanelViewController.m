//
//  SMSearchContentsPanelViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMessageThreadViewController.h"
#import "SMFindContentsPanelViewController.h"

@implementation SMFindContentsPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		;
	}
	
	return self;
}

- (IBAction)findContentsSearchAction:(id)sender {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];

	[[appController messageThreadViewController] findContents:_searchField.stringValue matchCase:(_matchCaseCheckbox.state == NSOnState) forward:YES];
}

- (IBAction)setMatchCaseAction:(id)sender {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[[appController messageThreadViewController] removeFindContentsResults];
	[[appController messageThreadViewController] findContents:_searchField.stringValue matchCase:(_matchCaseCheckbox.state == NSOnState) forward:YES];
}

- (IBAction)findNextAction:(id)sender {
	
}

- (IBAction)findPrevAction:(id)sender {
}

@end
