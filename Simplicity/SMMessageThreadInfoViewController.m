//
//  SMMessageThreadInfoViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/1/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMImageRegistry.h"
#import "SMMessageThread.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageThreadInfoViewController.h"

@implementation SMMessageThreadInfoViewController {
	SMMessageThread *_messageThread;
/*
	NSButton *_starButton;
*/
	NSTextField *_subject;
}

- (id)init {
	self = [super init];
	
	if(self) {
		NSBox *view = [[NSBox alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[view setBoxType:NSBoxCustom];
		[view setBorderColor:[NSColor lightGrayColor]];
		[view setBorderType:NSLineBorder];
		[view setCornerRadius:0];
		[view setTitlePosition:NSNoTitle];
		
		[self setView:view];
		
		[self initSubviews];
	}
	
	return self;
}

- (void)setMessageThread:(SMMessageThread*)messageThread {
/*
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];

	if(_messageThread.flagged) {
		_starButton.image = appDelegate.imageRegistry.yellowStarImage;
	} else {
		_starButton.image = appDelegate.imageRegistry.grayStarImage;
	}
*/
	
	[_subject setStringValue:[[messageThread.messagesSortedByDate firstObject] subject]];
}

#define H_MARGIN 6
#define V_MARGIN 10
#define FROM_W 5
#define H_GAP 5
#define V_GAP 10

- (void)initSubviews {
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	NSView *view = [self view];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:[SMMessageDetailsViewController headerHeight]]];
	
	// star
/*
	_starButton = [[NSButton alloc] init];
	_starButton.translatesAutoresizingMaskIntoConstraints = NO;
	_starButton.bezelStyle = NSShadowlessSquareBezelStyle;
	_starButton.target = self;
	_starButton.image = appDelegate.imageRegistry.grayStarImage;
	[_starButton.cell setImageScaling:NSImageScaleProportionallyDown];
	_starButton.bordered = NO;
	_starButton.action = @selector(toggleFullDetails:);

	[view addSubview:_starButton];
	
	[view addConstraint:[NSLayoutConstraint constraintWithItem:_starButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:[SMMessageDetailsViewController headerHeight]/[SMMessageDetailsViewController headerIconHeightRatio]]];
	
	[view addConstraint:[NSLayoutConstraint constraintWithItem:_starButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_starButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
	
	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_starButton attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_starButton attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN]];
*/
	
	// subject

	_subject = [SMMessageDetailsViewController createLabel:@"" bold:YES];
	_subject.textColor = [NSColor blackColor];
	
	[_subject.cell setLineBreakMode:NSLineBreakByTruncatingTail];
	[_subject setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow-2 forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	[view addSubview:_subject];
	
/*
	[view addConstraint:[NSLayoutConstraint constraintWithItem:_starButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];
*/

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_subject attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-H_MARGIN]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN]];
}

@end
