//
//  SMNewLabelWindowController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/5/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMSimplicityContainer.h"
#import "SMMailbox.h"
#import "SMFolder.h"
#import "SMNewLabelWindowController.h"

@implementation SMNewLabelWindowController

- (id)init {
	self = [super init];
	
	if(self) {
		[NSBundle loadNibNamed:@"SMNewLabelWindow" owner:self];
	}
	
	return self;
}

- (IBAction)createAction:(id)sender {
	NSLog(@"%s", __func__);
	
	// TODO
}

- (IBAction)cancelAction:(id)sender {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[appDelegate appController] hideNewLabelSheet];
}

- (void)windowWillClose:(NSNotification *)notification {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[appDelegate appController] hideNewLabelSheet];
}

- (IBAction)toggleNestedLabelAction:(id)sender {
	const Boolean nestLabel = (_labelNestedCheckbox.state == NSOnState);

	[_nestingLabelName setEnabled:nestLabel];
}

- (void)updateExistingLabelsList {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	SMMailbox *mailbox = [[appDelegate model] mailbox];

	NSMutableArray *labelsList = [NSMutableArray array];
	for(SMFolder *folder in mailbox.folders)
		[labelsList addObject:folder.fullName];

	[_nestingLabelName removeAllItems];
	[_nestingLabelName addItemsWithTitles:labelsList];
}

@end
