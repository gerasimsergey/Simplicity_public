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
#import "SMMessage.h"

@implementation SMMessageDetailsViewController {
	SMMessage *_currentMessage;

	NSTextField *_subject;
	NSTextField *_fromAddress;
	NSTokenField *_toAdresses;
///	NSTextField *_toAdresses;
	
	NSTextField *_toLabel;
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
//	[label setDrawsBackground:NO];
	[label setEditable:NO];
	[label setSelectable:NO];
	[label setFrameSize:[label fittingSize]];
//	[label setAutoresizingMask:NSViewWidthSizable];
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
#define V_GAP 10

- (void)createSubviews {
	NSView *view = [self view];

	if(_fromAddress == nil)
	{
		_fromAddress = [self createLabel:[_currentMessage from] bold:YES];
		_fromAddress.textColor = [NSColor blueColor];
		
		[view addSubview:_fromAddress];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_fromAddress attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];
		
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

	{
		_toLabel = [self createLabel:@"To:" bold:NO];
		_toLabel.textColor = [NSColor blackColor];
		
		[view addSubview:_toLabel];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN]];
		
	}
	
	{
		_toAdresses = [[SMTokenField alloc] initWithFrame:view.bounds];
		_toAdresses.delegate = self; // TODO: reference loop here?
		_toAdresses.tokenStyle = NSPlainTextTokenStyle;
		[_toAdresses setBordered:YES];
		_toAdresses.translatesAutoresizingMaskIntoConstraints = NO;

		// get the array of tokens
		NSArray *array = [_toAdresses objectValue];
		
		// copy the array so we can modify and add a new one
		NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];
		
		[newArray addObject:@"Bla"];
		[_toAdresses setObjectValue:newArray]; // commit the edit change
		
		// force the insertion point after the added token
		NSText *fieldEditor = [_toAdresses currentEditor];
		[fieldEditor setSelectedRange:NSMakeRange([[fieldEditor string] length], 0)];
		[fieldEditor setVerticallyResizable:YES];

		[view addSubview:_toAdresses];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:_toLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP]];

		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];

//		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP]];

//		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeTop multiplier:1.0 constant:-50]];
		
//		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toAdresses attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
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
	NSLog(@"%s", __func__);
	return @"Fred";
}

@end
