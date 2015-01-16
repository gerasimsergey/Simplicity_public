//
//  SMMessageThreadCellViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageDetailsViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMMessageThreadCellViewController.h"

@implementation SMMessageThreadCellViewController {
	SMMessageDetailsViewController *_messageDetailsViewController;

	NSView *_messageView;
	NSButton *_headerButton;
	NSProgressIndicator *_progressIndicator;
	NSLayoutConstraint *_heightConstraint;
	CGFloat _messageViewHeight;
	Boolean _collapsed;
	Boolean _messageTextIsSet;
}

- (id)initCollapsed:(Boolean)collapsed {
	self = [super init];
	
	if(self) {
		// init main view
		
		NSBox *view = [[NSBox alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[view setBoxType:NSBoxCustom];
		[view setBorderColor:[NSColor lightGrayColor]];
		[view setBorderType:NSLineBorder];
		[view setCornerRadius:2];
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

		[self addConstraint:_headerButton constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:[SMMessageDetailsViewController headerHeight]] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_headerButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];

		// init message view
		
		_messageDetailsViewController = [[SMMessageDetailsViewController alloc] init];
		
		NSView *messageDetailsView = [ _messageDetailsViewController view ];
		NSAssert(messageDetailsView, @"messageDetailsView");
		
		[view addSubview:messageDetailsView];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		_messageBodyViewController = [[SMMessageBodyViewController alloc] init];
		
		NSView *messageBodyView = [_messageBodyViewController view];
		NSAssert(messageBodyView, @"messageBodyView");
		
		[view addSubview:messageBodyView];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:messageDetailsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:messageBodyView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:0 multiplier:1.0 constant:300] priority:NSLayoutPriorityDefaultLow];

		// commit the main view
		
		[self setView:view];

		// now set the view constraints depending on the desired states

		_collapsed = !collapsed;

		[self toggleCollapse];
	}
	
	return self;
}

- (void)initProgressIndicator {
	NSAssert(_progressIndicator == nil, @"progress indicator already created");
	
	_progressIndicator = [[NSProgressIndicator alloc] init];
	_progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
	
	[_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
	[_progressIndicator setDisplayedWhenStopped:NO];
	[_progressIndicator startAnimation:self];
	
	NSView *view = [self view];
	
	[view addSubview:_progressIndicator];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:[_messageBodyViewController view] attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_progressIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:[_messageBodyViewController view] attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow-1];
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
	
	[_messageDetailsViewController collapseHeader];

	NSBox *view = (NSBox*)[self view];
	NSAssert(view != nil, @"view is nil");
	
	[view setFillColor:[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.96 alpha:1.0]];

	_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:[SMMessageDetailsViewController headerHeight]];
	
	[self addConstraint:view constraint:_heightConstraint priority:NSLayoutPriorityRequired];
	
	[_progressIndicator setHidden:YES];
	
	_collapsed = YES;
}

- (void)uncollapse {
	if(!_collapsed)
		return;

	NSBox *view = (NSBox*)[self view];
	NSAssert(view != nil, @"view is nil");
	
	[view setFillColor:[NSColor whiteColor]];
	
	[_messageDetailsViewController uncollapseHeader];	
	[_messageBodyViewController uncollapse];

	if(_heightConstraint != nil) {
		[[self view] removeConstraint:_heightConstraint];

		_heightConstraint = nil;
	}
	
	if(!_messageTextIsSet) {
		if(_progressIndicator == nil) {
			[self initProgressIndicator];
		} else {
			[_progressIndicator setHidden:NO];
		}
	}

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
	NSView *messageBodyView = [_messageBodyViewController view];
	NSAssert(messageBodyView, @"messageBodyView");
	
	[_messageBodyViewController setMessageViewText:htmlText uid:uid folder:folder];

	[_progressIndicator stopAnimation:self];

	_messageTextIsSet = YES;
}

- (void)setMessageDetails:(SMMessage*)message {
	[_messageDetailsViewController setMessageDetails:message];
}

- (void)updateMessageDetails {
	[_messageDetailsViewController updateMessageDetails];
}


@end
