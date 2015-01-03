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
	NSProgressIndicator *_progressIndicator;
	NSLayoutConstraint *_heightConstraint;
	CGFloat _messageViewHeight;
	BOOL _collapsed;
}

- (id)initCollapsed:(Boolean)collapsed {
	self = [super init];
	
	if(self) {
		// init main view
		
		NSBox *view = [[NSBox alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[view setTitlePosition:NSNoTitle];

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

		// commit the main view
		
		[self setView:view];

		// now set the view constraints depending on the desired states

		_collapsed = !collapsed;

		[self toggleCollapse];
	}
	
	return self;
}

- (void)enableCollapse:(Boolean)enable {
	[_headerButton setEnabled:enable];
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (void)collapse {
	if(_collapsed)
		return;

	NSView *view = [self view];
	
	_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:HEADER_HEIGHT];
	
	[self addConstraint:view constraint:_heightConstraint priority:NSLayoutPriorityRequired];
	
	[_progressIndicator setHidden:YES];
	
	_collapsed = YES;
}

- (void)uncollapse {
	if(!_collapsed)
		return;
	
	[[_messageViewController messageBodyViewController] uncollapse];

	if(_heightConstraint != nil) {
		NSView *view = [self view];

		[view removeConstraint:_heightConstraint];
		_heightConstraint = nil;
	}
	
	[_progressIndicator setHidden:NO];

	_collapsed = NO;
}

- (void)toggleCollapse {
	if(!_collapsed)
	{
		[self collapse];
	}
	else
	{
		[self uncollapse];
	}
}

- (void)buttonClicked:(id)sender {
	[self toggleCollapse];
}

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder {
	[_messageViewController setMessageViewText:htmlText uid:uid folder:folder];
	[_progressIndicator stopAnimation:self];
}

@end
