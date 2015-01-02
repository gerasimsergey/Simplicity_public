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
	NSTextField *_date;
	NSButton *_infoButton;
	NSTextField *_toLabel;
	NSTokenField *_toAddresses;
	NSTextField *_ccLabel;
	NSTokenField *_ccAddresses;
	Boolean _addressListsFramesValid;
	Boolean _fullDetailsInitialized;
	Boolean _fullDetailsShown;
	NSMutableArray *_fullDetailsConstraints;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_addressListsFramesValid = NO;
		_fullDetailsConstraints = [[NSMutableArray alloc] init];

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

- (void)updateFullDetails {
	if(!_fullDetailsInitialized)
		return;

	if(_currentMessage == nil)
		return;

	NSArray *toAddressArray = [_currentMessage.header to];
	NSMutableArray *newToArray = [[NSMutableArray alloc] initWithCapacity:toAddressArray.count];
	
	for(NSUInteger i = 0; i < toAddressArray.count; i++)
		newToArray[i] = [SMMessage parseAddress:toAddressArray[i]];

	[_toAddresses setObjectValue:newToArray];
	
	NSArray *ccAddressArray = [_currentMessage.header cc];
	NSMutableArray *newCcArray = [[NSMutableArray alloc] initWithCapacity:ccAddressArray.count];
	
	for(NSUInteger i = 0; i < ccAddressArray.count; i++)
		newCcArray[i] = [SMMessage parseAddress:ccAddressArray[i]];

	[_ccAddresses setObjectValue:newCcArray];
	
	_addressListsFramesValid = NO;
}

- (void)setMessageDetails:(SMMessage*)message {
	NSAssert(message != nil, @"nil message");
	
	Boolean updateAddressLists = NO;

	if(_currentMessage != message) {
		_currentMessage = message;
		
		[_fromAddress setStringValue:[_currentMessage from]];
		[_subject setStringValue:[_currentMessage subject]];
		[_date setStringValue:[_currentMessage localizedDate]];

		updateAddressLists = YES;
	} else {
		NSArray *currentToAddressList = [_toAddresses objectValue];

		if(currentToAddressList == nil || currentToAddressList.count == 0)
			updateAddressLists = YES;
	}

	if(updateAddressLists) {
		[self updateFullDetails];
	}
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
	
	_fromAddress = [self createLabel:@"" bold:YES];
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
	_infoButton.image = [NSImage imageNamed:NSImageNameInfo];
	_infoButton.bordered = NO;
	_infoButton.action = @selector(toggleFullDetails:);
	
	[view addSubview:_infoButton];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeRight multiplier:1.0 constant:H_MARGIN] priority:NSLayoutPriorityRequired-2];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_infoButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];

	// init date label
	
	_date = [self createLabel:@"" bold:NO];
	_date.textColor = [NSColor grayColor];
	
	[view addSubview:_date];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:_date attribute:NSLayoutAttributeLeft multiplier:1.0 constant:H_MARGIN] priority:NSLayoutPriorityDefaultLow];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_infoButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_date attribute:NSLayoutAttributeRight multiplier:1.0 constant:H_MARGIN] priority:NSLayoutPriorityRequired-2];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_date attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];

	// init subject
	
	_subject = [self createLabel:@"" bold:NO];
	_subject.textColor = [NSColor blackColor];

	[_subject.cell setLineBreakMode:NSLineBreakByTruncatingTail];
	[_subject setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow-2 forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	[view addSubview:_subject];
	
	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-FROM_W] priority:NSLayoutPriorityDefaultHigh];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:_subject attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:_date attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_GAP] priority:NSLayoutPriorityDefaultLow];

	[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_subject attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN] priority:NSLayoutPriorityRequired];
}

- (void)showFullDetails {
	NSAssert(_fullDetailsConstraints.count == 0, @"old constraints exist");
	
	NSView *view = [self view];

	// init 'to' label
	
	if(_toLabel == nil) {
		_toLabel = [self createLabel:@"To:" bold:NO];
		_toLabel.textColor = [NSColor blackColor];
	}
	
	[view addSubview:_toLabel];
	
	NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];
	
	constraint = [NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_MARGIN];
	[self addConstraint:view constraint:constraint priority:NSLayoutPriorityDefaultLow];
	[_fullDetailsConstraints addObject:constraint];
	
	// init 'to' address list
	
	if(_toAddresses == nil) {
		_toAddresses = [[SMTokenField alloc] init];
		_toAddresses.delegate = self; // TODO: reference loop here?
		_toAddresses.tokenStyle = NSPlainTextTokenStyle;
		_toAddresses.translatesAutoresizingMaskIntoConstraints = NO;
		[_toAddresses setBordered:NO];
		[_toAddresses setDrawsBackground:NO];
	}
	
	[view addSubview:_toAddresses];
	
	constraint = [NSLayoutConstraint constraintWithItem:_toLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_toAddresses attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];

	constraint = [NSLayoutConstraint constraintWithItem:_fromAddress attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toAddresses attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP];
	[self addConstraint:view constraint:constraint priority:NSLayoutPriorityDefaultLow];
	[_fullDetailsConstraints addObject:constraint];
	
	constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_toAddresses attribute:NSLayoutAttributeWidth multiplier:1.0 constant:H_MARGIN + _toLabel.frame.size.width];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];
	
	// init 'cc' label
	
	if(_ccLabel == nil) {
		_ccLabel = [self createLabel:@"Cc:" bold:NO];
		_ccLabel.textColor = [NSColor blackColor];
	}
	
	[view addSubview:_ccLabel];
	
	constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_ccLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-H_MARGIN];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];
	
	constraint = [NSLayoutConstraint constraintWithItem:_toAddresses attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_ccLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP_HALF];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];
	
	// init 'cc' address list
	
	if(_ccAddresses == nil) {
		_ccAddresses = [[SMTokenField alloc] init];
		_ccAddresses.delegate = self; // TODO: reference loop here?
		_ccAddresses.tokenStyle = NSPlainTextTokenStyle;
		_ccAddresses.translatesAutoresizingMaskIntoConstraints = NO;
		[_ccAddresses setBordered:NO];
		[_ccAddresses setDrawsBackground:NO];
	}
	
	[view addSubview:_ccAddresses];
	
	constraint = [NSLayoutConstraint constraintWithItem:_ccLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_ccAddresses attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];
	
	constraint = [NSLayoutConstraint constraintWithItem:_toAddresses attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_ccAddresses attribute:NSLayoutAttributeTop multiplier:1.0 constant:-V_GAP_HALF];
	[self addConstraint:view constraint:constraint priority:NSLayoutPriorityDefaultLow];
	[_fullDetailsConstraints addObject:constraint];
	
	constraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_ccAddresses attribute:NSLayoutAttributeWidth multiplier:1.0 constant:H_MARGIN + _ccLabel.frame.size.width];
	[view addConstraint:constraint];
	[_fullDetailsConstraints addObject:constraint];

	_fullDetailsInitialized = YES;
}

- (void)hideFullDetails {
	[[self view] removeConstraints:_fullDetailsConstraints];
	[_fullDetailsConstraints removeAllObjects];

	[_toLabel removeFromSuperview];
	[_toAddresses removeFromSuperview];
	[_ccLabel removeFromSuperview];
	[_ccAddresses removeFromSuperview];
}

- (void)addConstraint:(NSView*)view constraint:(NSLayoutConstraint*)constraint priority:(NSLayoutPriority)priority {
	constraint.priority = priority;
	[view addConstraint:constraint];
}

- (NSSize)intrinsicContentViewSize {
	if(_fullDetailsShown) {
		return NSMakeSize(-1, V_MARGIN + _fromAddress.frame.size.height + V_MARGIN + [_toAddresses intrinsicContentSize].height + V_GAP_HALF + [_ccAddresses intrinsicContentSize].height + V_GAP);
	} else {
		return NSMakeSize(-1, V_MARGIN + _fromAddress.frame.size.height + V_MARGIN);
	}
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
//	NSLog(@"%s", __func__);
	return NSRoundedTokenStyle;
}

// ---------------------------------------------------------------------------
//	hasMenuForRepresentedObject:representedObject
//
//	Make sure our tokens have a menu. By default tokens have no menus.
// ---------------------------------------------------------------------------
- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
//	NSLog(@"%s", __func__);
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

- (void)viewDidAppear {
	if(!_addressListsFramesValid) {
		// this is critical because the frame height for each SMTokenField must be
		// recalculated after its width is known, which happens when it is drawn
		// for the first time
		
		[_toAddresses invalidateIntrinsicContentSize];
		[_ccAddresses invalidateIntrinsicContentSize];
		
		_addressListsFramesValid = YES;
	}
}

- (void)toggleFullDetails:(id)sender {
	if(_fullDetailsShown) {
		[self hideFullDetails];
	} else {
		[self showFullDetails];
	}
	
	[self updateFullDetails];

	// this must be done to keep the proper details panel height
	[[self view] invalidateIntrinsicContentSize];

	_fullDetailsShown = !_fullDetailsShown;
}

@end
