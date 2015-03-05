//
//  SMNewLabelWindowController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/5/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
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
	NSLog(@"%s", __func__);

	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[appDelegate appController] hideNewLabelSheet];
}

@end
