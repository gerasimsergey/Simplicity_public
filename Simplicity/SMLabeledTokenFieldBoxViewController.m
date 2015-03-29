//
//  SMLabeledTokenFieldBoxViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/28/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMTokenField.h"
#import "SMLabeledTokenFieldBoxView.h"
#import "SMLabeledTokenFieldBoxViewController.h"

@implementation SMLabeledTokenFieldBoxViewController {
	Boolean _tokenFieldFramesValid;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	NSView *view = [self view];

	NSAssert([view isKindOfClass:[SMLabeledTokenFieldBoxView class]], @"bad view class");
	
	[(SMLabeledTokenFieldBoxView*)view setViewController:self];
}

- (void)viewDidAppear {
	if(!_tokenFieldFramesValid) {
		// this is critical because the frame height for each SMTokenField must be
		// recalculated after its width is known, which happens when it is drawn
		// for the first time

		[_tokenField invalidateIntrinsicContentSize];
		
		_tokenFieldFramesValid = YES;
	}
}

- (NSSize)intrinsicContentViewSize {
	return NSMakeSize(-1, [_label intrinsicContentSize].height);
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

@end
