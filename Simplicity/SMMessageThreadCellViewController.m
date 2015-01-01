//
//  SMMessageThreadCellViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMMessageThreadCellViewController.h"

static const NSUInteger HEADER_HEIGHT = 36;

@implementation SMMessageThreadCellViewController {
	NSView *_messageView;
	NSButton *_headerButton;
	NSButton *_infoButton;
	NSProgressIndicator *_progressIndicator;
	NSLayoutConstraint *_heightConstraint;
	CGFloat _messageViewHeight;
	BOOL _collapsed;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_collapsed = false;

		// init main view
		
		NSBox *view = [[NSBox alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[view setTitlePosition:NSNoTitle];

		// init info button
		
		_infoButton = [[NSButton alloc] init];
		_infoButton.translatesAutoresizingMaskIntoConstraints = NO;
		_infoButton.bezelStyle = NSShadowlessSquareBezelStyle;
		_infoButton.target = self;
		_infoButton.action = @selector(buttonClicked:);
		
		[_infoButton setTransparent:YES];
		[_infoButton setEnabled:NO];
		
		[view addSubview:_infoButton];

		// init header button

		_headerButton = [[NSButton alloc] init];
		_headerButton.translatesAutoresizingMaskIntoConstraints = NO;
		_headerButton.bezelStyle = NSShadowlessSquareBezelStyle;
		_headerButton.target = self;
		_headerButton.action = @selector(buttonClicked:);

		[_headerButton setTransparent:YES];
		[_headerButton setEnabled:NO];

		[view addSubview:_headerButton];

		[self addConstraint:_headerButton constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:HEADER_HEIGHT] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];

		// init message view
		
		_messageViewController = [[SMMessageViewController alloc] init];

		_messageView = [_messageViewController view];
		_messageView.translatesAutoresizingMaskIntoConstraints = NO;

		[view addSubview:_messageView];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		 
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];

		// init progress indicator

		_progressIndicator = [[NSProgressIndicator alloc] init];
		_progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
		
		[_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
		[_progressIndicator setDisplayedWhenStopped:NO];
		[_progressIndicator startAnimation:self];
		
		[view addSubview:_progressIndicator];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:[[_messageViewController messageBodyViewController] view] attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:[[_messageViewController messageBodyViewController] view] attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];
		
		// finally, commit the main view
		
		[self setView:view];
	}
	
	return self;
}

- (void)enableCollapse {
	[_headerButton setEnabled:YES];
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (void)setCollapsedView {
	NSView *view = [self view];
	
	if(!_collapsed)
	{
		[_progressIndicator setHidden:YES];
		
		NSAssert(_heightConstraint == nil, @"height constraint already exists");
		
		_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:HEADER_HEIGHT];
		
		[self addConstraint:view constraint:_heightConstraint priority:NSLayoutPriorityRequired];
		
		_collapsed = YES;
	}
}

- (void)unsetCollapsedView {
	NSView *view = [self view];
	
	if(_collapsed)
	{
		[view removeConstraint:_heightConstraint];
		
		_heightConstraint = nil;
		
		_collapsed = NO;
		
		[_progressIndicator setHidden:NO];
	}
}

- (void)toggleCollapsedView {
	if(!_collapsed)
	{
		[self setCollapsedView];
	}
	else
	{
		[self unsetCollapsedView];
	}
}

- (void)buttonClicked:(id)sender {
	[self toggleCollapsedView];
}

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder {
	[_messageViewController setMessageViewText:htmlText uid:uid folder:folder];
	[_progressIndicator stopAnimation:self];
}

@end
