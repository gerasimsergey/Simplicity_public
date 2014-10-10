//
//  SMMessageDetailsViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/11/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMMessageDetailsViewController.h"
#import "SMMessage.h"

@implementation SMMessageDetailsViewController {
	SMMessage *_currentMessage;

	NSTextField *_fromLabel;
	NSTextField *_fromAddressLabel;
	NSTextField *_toLabel;
	NSMutableArray *_toAddressLabels;
	NSTextField *_ccLabel;
	NSMutableArray *_ccAddressLabels;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(100, 100, 100, 300)];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[self setView:view];
	}
	
	return self;
}

		
#define H_MARGIN 5
#define H_GAP 2
#define V_GAP 2

- (NSTextField*)createLabel:(NSString*)text {
	NSTextField *label = [[NSTextField alloc] init];
	
	[label setStringValue:text];
	[label setBordered:YES];
	[label setBezeled:NO];
	[label setDrawsBackground:NO];
	[label setEditable:NO];
	[label setSelectable:NO];
//	[label setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[label setFrameSize:[label fittingSize]];
	[label setTranslatesAutoresizingMaskIntoConstraints:NO];

	return label;
}

- (void)setMessageDetails:(SMMessage*)message {
	NSAssert(message != nil, @"nil message");
	
	_currentMessage = message;
	
	[self createSubviews];
	[self adjustDetailsLayout];
}

- (void)createSubviews {
	NSView *view = [self view];
	[view setSubviews:[NSArray array]];

	if(!_fromLabel)
		_fromLabel = [self createLabel:@"From:"];
	
	[view addSubview:_fromLabel];
	
	if(!_toLabel)
		_toLabel = [self createLabel:@"To:"];
	
	[view addSubview:_toLabel];
	
	if(!_ccLabel)
		_ccLabel = [self createLabel:@"CC:"];
	
	[view addSubview:_ccLabel];

	_fromAddressLabel = [self createLabel:[_currentMessage from]];
	
	[view addSubview:_fromAddressLabel];
	
	if(_toAddressLabels)
		[_toAddressLabels removeAllObjects];
	else
		_toAddressLabels = [NSMutableArray new];
	
	if(_ccAddressLabels)
		[_ccAddressLabels removeAllObjects];
	else
		_ccAddressLabels = [NSMutableArray new];
		
	MCOMessageHeader *header = [_currentMessage header];
	
	if(!header)
	{
		NSLog(@"%s: Message header is empty", __FUNCTION__);
		return;
	}
	
	for(MCOAddress *to in [header to]) {
		NSLog(@"to: %@", [SMMessage parseAddress:to]);
		
		NSTextField *label = [self createLabel:[SMMessage parseAddress:to]];
		
		[_toAddressLabels addObject:label];
		
		[view addSubview:label];
	}

	for(MCOAddress *cc in [header cc]) {
		NSLog(@"cc: %@", [SMMessage parseAddress:cc]);
		
		NSTextField *label = [self createLabel:[SMMessage parseAddress:cc]];

		[_ccAddressLabels addObject:label];

		[view addSubview:label];
	}
}

- (void)adjustDetailsLayout {
	if(_fromLabel == nil) {
		return;
	}
	
	NSAssert(_fromAddressLabel, @"bad _fromAddressLabel");
	NSAssert(_toLabel, @"bad _toLabel");
	NSAssert(_ccLabel, @"bad _ccLabel");
	
	NSView *view = [self view];

	NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_fromLabel, _fromAddressLabel, _toLabel, _ccLabel);
	
//	[view removeConstraints:[view constraints]];

	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_fromLabel]" options:0 metrics:nil views:viewsDictionary]];
	
	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_fromLabel]" options:0 metrics:nil views:viewsDictionary]];

	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_toLabel]" options:0 metrics:nil views:viewsDictionary]];
	
	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_ccLabel]" options:0 metrics:nil views:viewsDictionary]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_fromAddressLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_fromAddressLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
	
	if([_toAddressLabels count] > 0) {
		[view addConstraint:[NSLayoutConstraint constraintWithItem:[_toAddressLabels lastObject] attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_ccLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];
	
		[self arrangeLabels:_toAddressLabels anchor:_toLabel];
	}
	
	if([_ccAddressLabels count] > 0) {
		[self arrangeLabels:_ccAddressLabels anchor:_ccLabel];
	}
	
	[view setNeedsUpdateConstraints:YES];
}

- (void)arrangeLabels:(NSArray*)labels anchor:(NSView*)anchor {
	NSView *view = [self view];
	NSView *rightmost = anchor;
	
	CGFloat minWidth = H_MARGIN * 2 + [anchor bounds].size.width;
	Boolean firstInRow = YES;
	
	for(NSTextField *label in labels) {
		CGFloat labelWidth = [label bounds].size.width;
		
		if(firstInRow || minWidth + H_GAP + labelWidth <= [view bounds].size.width) {
			[view addConstraint:[NSLayoutConstraint constraintWithItem:rightmost attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];
			
			[view addConstraint:[NSLayoutConstraint constraintWithItem:rightmost attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
			
			minWidth += (firstInRow? 0 : H_GAP) + labelWidth;
			rightmost = label;
			firstInRow = NO;
		} else {
			[view addConstraint:[NSLayoutConstraint constraintWithItem:anchor attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];
			
			[view addConstraint:[NSLayoutConstraint constraintWithItem:rightmost attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
			
			minWidth = H_MARGIN * 2 + [anchor bounds].size.width + H_GAP + labelWidth;
			rightmost = label;
		}
	}

}

@end
