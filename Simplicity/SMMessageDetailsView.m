//
//  SMMessageDetailsView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/26/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMessageViewController.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageDetailsView.h"

@implementation SMMessageDetailsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }

	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
/*	if(![self inLiveResize]) {
		[super drawRect:dirtyRect];

		return;
	}
  */
/*
 SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
	SMAppController *appController = [appDelegate appController];
	
	[[appController messageDetailsViewController] arrange];
*/
	//NSView *vv = [appController messageDetailsView];
//	NSLog(@"self %@, appController messageDetailsView %@", self, vv);
	
//	[[appController messageDetailsView] updateSelectedMessageView];

    // TODO
	
//	NSLog(@"%s", __FUNCTION__);
}


- (void)viewWillStartLiveResize
{
	NSLog(@"%s", __FUNCTION__);
	
    // TODO

	[super viewWillStartLiveResize];
}

- (void)viewDidEndLiveResize
{
	NSLog(@"%s", __FUNCTION__);

    // TODO
//	SMAppDelegate *appDelegate =  [[ NSApplication sharedApplication ] delegate];
//	SMAppController *appController = [appDelegate appController];

//	TODO
//	[[appController messageViewController] adjustDetailsLayout];

	[super viewDidEndLiveResize];
}


@end
