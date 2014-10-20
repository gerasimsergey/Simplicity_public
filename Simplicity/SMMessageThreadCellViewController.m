//
//  SMMessageThreadCellViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageViewController.h"
#import "SMMessageThreadCellViewController.h"

static const NSUInteger HEADER_HEIGHT = 36;

@implementation SMMessageThreadCellViewController {
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

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];
		 
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_messageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultHigh];

		// finally, commit the main view
		
		[self setView:view];
	}
	
	return self;
}

- (void)enableCollapse {
	NSView *view = [self view];
	
	NSLog(@"%s: view frame %f x %f", __func__, view.frame.size.width, view.frame.size.height);
/*
	_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:_height];
	
	[self addConstraint:view constraint:_heightConstraint priority:NSLayoutPriorityRequired];
*/
	[_headerButton setEnabled:YES];
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (void)buttonClicked:(id)sender {
#if 0
	NSView *view = [self view];
	NSView *box = [view superview];
	NSView *contentView = [box superview];
	
	CGFloat heightDelta = (!_collapsed? [_messageView frame].size.height : _messageViewHeight) - HEADER_HEIGHT;
	
	NSAssert(heightDelta > 0, @"too small message view height");

	if(!_collapsed)
	{
		_messageViewHeight = [_messageView frame].size.height;
		
		NSRect ff;
		
		ff = [box frame];
		ff.size.height -= heightDelta;
		[box setFrame:ff];
		
		ff = [contentView frame];
		ff.size.height -= heightDelta;
		[contentView setFrame:ff];
		
		NSAssert(_height > heightDelta, @"bad message view height");

		_height -= heightDelta;
		_collapsed = YES;
	}
	else
	{
		NSRect ff;
		
		ff = [box frame];
		ff.size.height += heightDelta;
		[box setFrame:ff];
		
		ff = [contentView frame];
		ff.size.height += heightDelta;
		[contentView setFrame:ff];
		
		_height += heightDelta;
		_collapsed = NO;
	}

	[view removeConstraint:_heightConstraint];

	_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:_height];
	
	[self addConstraint:view constraint:_heightConstraint priority:NSLayoutPriorityRequired];
#endif
}

@end
