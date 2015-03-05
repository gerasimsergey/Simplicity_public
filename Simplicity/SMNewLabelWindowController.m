//
//  SMNewLabelWindowController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/5/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMNewLabelWindowController.h"

@implementation SMNewLabelWindowController

- (id)init {
	self = [super init];
	
	if(self) {
		[NSBundle loadNibNamed:@"SMNewLabelWindow" owner:self];
	}
	
	return self;
}

- (IBAction)createLabelAction:(id)sender {
	NSLog(@"%s", __func__);
	
	// TODO
}

- (IBAction)cancelLabelCreationAction:(id)sender {
	NSLog(@"%s", __func__);
	
//	[NSApp endSheet:_sheetNewLabel];
}

@end
