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

	NSTextField *_subject;
	NSTextField *_fromAddress;
	NSTextField *_toLabel;
	NSMutableArray *_toAddresses;
	NSTextField *_ccLabel;
	NSMutableArray *_ccAddresses;
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

		
- (NSTextField*)createLabel:(NSString*)text bold:(BOOL)bold {
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
	
	_currentMessage = message;
	
	[self createSubviews];
	[self adjustDetailsLayout];
}

#define V_MARGIN 10
#define H_MARGIN 5
#define FROM_W 5
#define H_GAP 5
#define V_GAP 5

- (void)createSubviews {
	NSView *view = [self view];

	if(_fromAddress == nil)
	{
		_fromAddress = [self createLabel:[_currentMessage from] bold:YES];
		_fromAddress.textColor = [NSColor blueColor];
		
		[view addSubview:_fromAddress];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN]];
	}

	if(_subject == nil)
	{
		_subject = [self createLabel:[_currentMessage subject] bold:NO];
		_subject.textColor = [NSColor blackColor];
		
		[view addSubview:_subject];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-FROM_W]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN]];
	}
	
	// TODO: use NSTokenField fo the rest!

/*
	[view setSubviews:[NSArray array]];

	if(!_toLabel)
		_toLabel = [self createLabel:@"To:"];
	
	[view addSubview:_toLabel];
	
	if(!_ccLabel)
		_ccLabel = [self createLabel:@"CC:"];
	
	[view addSubview:_ccLabel];

	_fromAddress = [self createLabel:[_currentMessage from]];
	
	[view addSubview:_fromAddress];
	
	if(_toAddresses)
		[_toAddresses removeAllObjects];
	else
		_toAddresses = [NSMutableArray new];
	
	if(_ccAddresses)
		[_ccAddresses removeAllObjects];
	else
		_ccAddresses = [NSMutableArray new];
		
	MCOMessageHeader *header = [_currentMessage header];
	
	if(!header)
	{
		NSLog(@"%s: Message header is empty", __FUNCTION__);
		return;
	}
	
	for(MCOAddress *to in [header to]) {
		NSLog(@"to: %@", [SMMessage parseAddress:to]);
		
		NSTextField *label = [self createLabel:[SMMessage parseAddress:to]];
		
		[_toAddresses addObject:label];
		
		[view addSubview:label];
	}

	for(MCOAddress *cc in [header cc]) {
		NSLog(@"cc: %@", [SMMessage parseAddress:cc]);
		
		NSTextField *label = [self createLabel:[SMMessage parseAddress:cc]];

		[_ccAddresses addObject:label];

		[view addSubview:label];
	}
*/
}

- (void)adjustDetailsLayout {
/*
	NSAssert(_fromAddress, @"bad _fromAddressLabel");
//	NSAssert(_toLabel, @"bad _toLabel");
//	NSAssert(_ccLabel, @"bad _ccLabel");
	
	NSView *view = [self view];

//	[view removeConstraints:[view constraints]];


	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_ccLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
	
	if([_toAddresses count] > 0) {
		[view addConstraint:[NSLayoutConstraint constraintWithItem:[_toAddresses lastObject] attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_ccLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];
	
		[self arrangeLabels:_toAddresses anchor:_toLabel];
	}
	
	if([_ccAddresses count] > 0) {
		[self arrangeLabels:_ccAddresses anchor:_ccLabel];
	}
*/
	
//	[view setNeedsUpdateConstraints:YES];
}

- (void)arrangeLabels:(NSArray*)labels anchor:(NSView*)anchor {
/*
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
 */

}

@end
