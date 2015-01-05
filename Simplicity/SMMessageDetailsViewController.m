//
//  SMMessageDetailsViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/11/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMMessageDetailsViewController.h"
#import "SMMessageFullDetailsViewController.h"
#import "SMMessage.h"

@implementation SMMessageDetailsViewController {
	SMMessage *_currentMessage;

	NSTextField *_subject;
	NSTextField *_fromAddress;
	NSTextField *_date;
	NSButton *_infoButton;
	Boolean _fullDetailsShown;
	
	SMMessageFullDetailsViewController *_fullDetailsViewController;
	NSMutableArray *_fullDetailsViewConstraints;
	NSLayoutConstraint *_bottomConstraint;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		NSView *view = [[NSView alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[self setView:view];
		[self createSubviews];
	}
	
	return self;
}

+ (NSUInteger)headerHeight {
	return 36;
}

+ (NSTextField*)createLabel:(NSString*)text bold:(BOOL)bold {
	NSTextField *label = [[NSTextField alloc] init];
	
	[label setStringValue:text];
	[label setBordered:YES];
	[label setBezeled:NO];
	[label setDrawsBackground:NO];
	[label setEditable:NO];
	[label setSelectable:NO];
	[label setFrameSize:[label fittingSize]];
	[label setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	const NSUInteger fontSize = 12;
	[label setFont:(bold? [NSFont boldSystemFontOfSize:fontSize] : [NSFont systemFontOfSize:fontSize])];

	return label;
}

- (void)setMessageDetails:(SMMessage*)message {
	NSAssert(message != nil, @"nil message");
	
	if(_currentMessage != message) {
		_currentMessage = message;
		
		[_fromAddress setStringValue:[_currentMessage from]];
		[_subject setStringValue:[_currentMessage subject]];
		[_date setStringValue:[_currentMessage localizedDate]];
	}

	[_fullDetailsViewController setMessageDetails:message];
}

#define V_MARGIN 10
#define H_MARGIN 5
#define FROM_W 5
#define H_GAP 5
#define V_GAP 10
#define V_GAP_HALF (V_GAP/2)

- (void)createSubviews {
	NSView *view = [self view];

	// init from address label
	
	_fromAddress = [SMMessageDetailsViewController createLabel:@"" bold:YES];
	_fromAddress.textColor = [NSColor blueColor];

	[_fromAddress.cell setLineBreakMode:NSLineBreakByTruncatingTail];
	[_fromAddress setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow-1 forOrientation:NSLayoutConstraintOrientationHorizontal];

	[view addSubview:_fromAddress];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN] priority:NSLayoutPriorityRequired];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	// init info button
	
	_infoButton = [[NSButton alloc] init];
	_infoButton.translatesAutoresizingMaskIntoConstraints = NO;
	_infoButton.bezelStyle = NSShadowlessSquareBezelStyle;
	_infoButton.target = self;
	_infoButton.image = [NSImage imageNamed:@"info-icon.png"];
	[_infoButton.cell setImageScaling:NSImageScaleProportionallyDown];
	_infoButton.bordered = NO;
	_infoButton.action = @selector(toggleFullDetails:);
	
	[view addSubview:_infoButton];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeRight multiplier:1.0 constant:H_MARGIN] priority:NSLayoutPriorityRequired-2];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_infoButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:[SMMessageDetailsViewController headerHeight]/1.6]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_infoButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];

	// init date label
	
	_date = [SMMessageDetailsViewController createLabel:@"" bold:NO];
	_date.textColor = [NSColor grayColor];
	
	[view addSubview:_date];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:_date attribute:NSLayoutAttributeLeft multiplier:1.0 constant:H_MARGIN] priority:NSLayoutPriorityDefaultLow];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_infoButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_date attribute:NSLayoutAttributeRight multiplier:1.0 constant:H_GAP] priority:NSLayoutPriorityRequired-2];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_date attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	// init subject
	
	_subject = [SMMessageDetailsViewController createLabel:@"" bold:NO];
	_subject.textColor = [NSColor blackColor];

	[_subject.cell setLineBreakMode:NSLineBreakByTruncatingTail];
	[_subject setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow-2 forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	[view addSubview:_subject];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-FROM_W] priority:NSLayoutPriorityDefaultHigh];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_subject attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:_date attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP] priority:NSLayoutPriorityDefaultLow];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	_bottomConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeBottom multiplier:1.0 constant:V_MARGIN];
	
	[view addConstraint:_bottomConstraint];
}

- (void)showFullDetails {
	if(_fullDetailsShown)
		return;

	if(_fullDetailsViewController == nil)
		_fullDetailsViewController = [[SMMessageFullDetailsViewController alloc] init];
	
	if(_currentMessage != nil)
		[_fullDetailsViewController setMessageDetails:_currentMessage];

	NSView *view = [self view];
	NSAssert(view != nil, @"no view");

	NSView *subview = [_fullDetailsViewController view];
	NSAssert(subview != nil, @"no full details view");
	
	[view addSubview:subview];

	NSAssert(_bottomConstraint != nil, @"no bottom constraint");
	[view removeConstraint:_bottomConstraint];
	
	if(_fullDetailsViewConstraints == nil) {
		_fullDetailsViewConstraints = [NSMutableArray array];
		
		[_fullDetailsViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];
		
		[_fullDetailsViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeRight multiplier:1.0 constant:H_MARGIN]];
		
		[_fullDetailsViewConstraints addObject:[NSLayoutConstraint constraintWithItem:_subject attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];
		
		[_fullDetailsViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview attribute:NSLayoutAttributeBottom multiplier:1.0 constant:V_MARGIN]];
	}

	[view addConstraints:_fullDetailsViewConstraints];
	
	_fullDetailsShown = YES;
}

- (void)hideFullDetails {
	if(!_fullDetailsShown)
		return;

	NSView *view = [self view];
	NSAssert(view != nil, @"no view");

	NSAssert(_fullDetailsViewConstraints != nil, @"no full details view constraint");
	[view removeConstraints:_fullDetailsViewConstraints];

	NSAssert(_fullDetailsViewController != nil, @"no full details view controller");
	[[_fullDetailsViewController view] removeFromSuperview];
	
	[view addConstraint:_bottomConstraint];
	
	_fullDetailsShown = NO;
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (void)toggleFullDetails:(id)sender {
	if(_fullDetailsShown) {
		[self hideFullDetails];
	} else {
		[self showFullDetails];
	}

	// this must be done to keep the proper details panel height
	[[self view] invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentViewSize {
	if(_fullDetailsShown) {
		return NSMakeSize(-1, V_MARGIN + _fromAddress.frame.size.height + V_GAP + _fullDetailsViewController.view.intrinsicContentSize.height + V_MARGIN);
	} else {
		return NSMakeSize(-1, V_MARGIN + _fromAddress.frame.size.height + V_MARGIN);
	}
}

- (void)invalidateIntrinsicContentViewSize {
	[[self view] setNeedsUpdateConstraints:YES];
}

@end
