//
//  SMMessageDetailsViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/11/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SMTokenField.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageDetailsView.h"
#import "SMMessage.h"

@implementation SMMessageDetailsViewController {
	SMMessage *_currentMessage;

	NSTextField *_subject;
	NSTextField *_fromAddress;
	NSTextField *_toLabel;
	NSTokenField *_toAdresses;
	NSTextField *_ccLabel;
	NSMutableArray *_ccAddresses;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		SMMessageDetailsView *view = [[SMMessageDetailsView alloc] init];
		view.translatesAutoresizingMaskIntoConstraints = NO;
		[view setViewController:self];
		[self setView:view];
		[self createSubviews];
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

	[_fromAddress setStringValue:[_currentMessage from]];
	[_subject setStringValue:[_currentMessage subject]];
	
	NSArray *array = [_toAdresses objectValue];
	NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];
	
	for(MCOAddress *to in [message.header to])
		[newArray addObject:[SMMessage parseAddress:to]];

	[_toAdresses setObjectValue:newArray];
	
	// force the insertion point after the added token
	NSText *fieldEditor = [_toAdresses currentEditor];
	[fieldEditor setSelectedRange:NSMakeRange([[fieldEditor string] length], 0)];
	
	[[self view] invalidateIntrinsicContentSize];
}

#define V_MARGIN 10
#define H_MARGIN 5
#define FROM_W 5
#define H_GAP 5
#define V_GAP 10

- (void)createSubviews {
	NSView *view = [self view];

	// init from address label
	
	_fromAddress = [self createLabel:@"" bold:YES];
	_fromAddress.textColor = [NSColor blueColor];
	
	[view addSubview:_fromAddress];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN] priority:NSLayoutPriorityRequired];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	// init subject
	
	_subject = [self createLabel:@"" bold:NO];
	_subject.textColor = [NSColor blackColor];
	
	[view addSubview:_subject];
	
	[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-FROM_W]];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	// init to label

	_toLabel = [self createLabel:@"To:" bold:NO];
	_toLabel.textColor = [NSColor blackColor];
	
	[view addSubview:_toLabel];
	
	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityDefaultLow];

	// init 'to' address list

	_toAdresses = [[SMTokenField alloc] init];
	_toAdresses.delegate = self; // TODO: reference loop here?
	_toAdresses.tokenStyle = NSPlainTextTokenStyle;
	_toAdresses.translatesAutoresizingMaskIntoConstraints = NO;
	[_toAdresses setBordered:NO];
	[_toAdresses setDrawsBackground:NO];

	[view addSubview:_toAdresses];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:_toLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP] priority:NSLayoutPriorityDefaultLow];

	[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeWidth multiplier:1.0 constant:H_MARGIN + _toLabel.frame.size.width]];
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (NSSize)intrinsicContentViewSize {
	NSSize sz = NSMakeSize(-1, V_MARGIN + _fromAddress.frame.size.height + V_MARGIN + [_toAdresses intrinsicContentSize].height + V_GAP);
	return sz;
}

- (void)invalidateIntrinsicContentViewSize {
	[[self view] setNeedsUpdateConstraints:YES];
}

#pragma mark - NSTokenFieldDelegate

// ---------------------------------------------------------------------------
//	styleForRepresentedObject:representedObject
//
//	Make sure our tokens are rounded.
//	The delegate should return:
//		NSDefaultTokenStyle, NSPlainTextTokenStyle or NSRoundedTokenStyle.
// ---------------------------------------------------------------------------
- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	NSLog(@"%s", __func__);
	return NSRoundedTokenStyle;
}

// ---------------------------------------------------------------------------
//	hasMenuForRepresentedObject:representedObject
//
//	Make sure our tokens have a menu. By default tokens have no menus.
// ---------------------------------------------------------------------------
- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
	NSLog(@"%s", __func__);
	return NO;
}

// ---------------------------------------------------------------------------
//	menuForRepresentedObject:representedObject
//
//	User clicked on a token, return the menu we want to represent for our token.
//	By default tokens have no menus.
// ---------------------------------------------------------------------------
- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
	NSLog(@"%s", __func__);
	return nil;
}

// ---------------------------------------------------------------------------
//	shouldAddObjects:tokens:index
//
//	Delegate method to decide whether the given token list should be allowed,
//	we can selectively add/remove any token we want.
//
//	The delegate can return the array unchanged or return a modified array of tokens.
//	To reject the add completely, return an empty array.  Returning nil causes an error.
// ---------------------------------------------------------------------------
- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSLog(@"%s", __func__);
	return nil;
/*
	NSMutableArray *newArray = [NSMutableArray arrayWithArray:tokens];
	
	id aToken;
	for (aToken in newArray)
	{
		if ([[aToken description] isEqualToString:self.tokenTitleToAdd])
		{
			MyToken *token = [[MyToken alloc] init];
			token.name = [aToken description];
			[newArray replaceObjectAtIndex:index withObject:token];
			break;
		}
	}
	
	return newArray;
*/
}

// ---------------------------------------------------------------------------
//	completionsForSubstring:substring:tokenIndex:selectedIndex
//
//	Called 1st, and again every time a completion delay finishes.
//
//	substring =		the partial string that to be completed.
//	tokenIndex =	the index of the token being edited.
//	selectedIndex = allows you to return by-reference an index in the array
//					specifying which of the completions should be initially selected.
// ---------------------------------------------------------------------------
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex
	indexOfSelectedItem:(NSInteger *)selectedIndex
{
	NSLog(@"%s", __func__);
	return nil;
}

// ---------------------------------------------------------------------------
//	representedObjectForEditingString:editingString
//
//	Called 2nd, after you choose a choice from the menu list and press return.
//
//	The represented object must implement the NSCoding protocol.
//	If your application uses some object other than an NSString for their represented objects,
//	you should return a new instance of that object from this method.
//
// ---------------------------------------------------------------------------
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
	NSLog(@"%s", __func__);
	return @"Wilma";
}

// ---------------------------------------------------------------------------
//	displayStringForRepresentedObject:representedObject
//
//	Called 3rd, once the token is ready to be displayed.
//
//	If you return nil or do not implement this method, then representedObject
//	is displayed as the string. The represented object must implement the NSCoding protocol.
// ---------------------------------------------------------------------------
- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
//	NSLog(@"%s", __func__);
	return representedObject;
}

@end
