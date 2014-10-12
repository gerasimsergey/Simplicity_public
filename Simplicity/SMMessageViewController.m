 //
//  SMMessageViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/25/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WebKit/WebView.h>

#import "SMMessageViewController.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMAppDelegate.h"

@implementation SMMessageViewController {
	SMMessageDetailsViewController *_messageDetailsViewController;
	SMMessageBodyViewController *_messageBodyViewController;
	NSProgressIndicator *_progressIndicator;
}

#define DETAILS_H 200

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(100, 100, 100, 300)];
		view.translatesAutoresizingMaskIntoConstraints = NO;

		_messageDetailsViewController = [[SMMessageDetailsViewController alloc] init];
		
		NSView *messageDetailsView = [ _messageDetailsViewController view ];
		NSAssert(messageDetailsView, @"messageDetailsView");

		[view addSubview:messageDetailsView];

		[self addConstraint:messageDetailsView constraint:[NSLayoutConstraint constraintWithItem:messageDetailsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:DETAILS_H] priority:NSLayoutPriorityDefaultLow];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		_messageBodyViewController = [[SMMessageBodyViewController alloc] init];

		NSView *messageBodyView = [_messageBodyViewController view];
		NSAssert(messageBodyView, @"messageBodyView");
		
		[view addSubview:messageBodyView];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:messageDetailsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];

		_progressIndicator = [NSProgressIndicator new];
		_progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		
		[_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[_progressIndicator setDisplayedWhenStopped:NO];
		[_progressIndicator startAnimation:self];
		
		[view addSubview:_progressIndicator];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];
	
		[self setView:view];
	}
	
	return self;
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder {
	NSView *messageBodyView = [_messageBodyViewController view];
	NSAssert(messageBodyView, @"messageBodyView");

	[_messageBodyViewController setMessageViewText:htmlText uid:uid folder:folder];
	[_progressIndicator stopAnimation:self];
}

- (void)setMessageDetails:(SMMessage*)message {
	[_messageDetailsViewController setMessageDetails:message];
}

@end
