//
//  SMAppController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMAppController.h"
#import "SMMailboxViewController.h"
#import "SMSearchResultsListController.h"
#import "SMSearchResultsListViewController.h"
#import "SMMessageListController.h"
#import "SMMessageListViewController.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageThreadViewController.h"
#import "SMInstrumentPanelViewController.h"

static NSString *SearchDocToolbarItemIdentifier = @"Search Item Identifier";

@implementation SMAppController {
	NSButton *button1, *button2;
	NSToolbarItem *__weak _activeSearchItem;
}

- (void)awakeFromNib {
	NSLog(@"SMAppController: awakeFromNib: _messageListViewController %@", _messageListViewController);
	
	SMAppDelegate *appDelegate = [[ NSApplication sharedApplication ] delegate];
	appDelegate.appController = self;

	//
	
	_instrumentPanelViewController = [ [ SMInstrumentPanelViewController alloc ] initWithNibName:@"SMInstrumentPanelViewController" bundle:nil ];
	
	NSAssert(_instrumentPanelViewController, @"_instrumentPanelViewController");
	
	NSView *instrumentPanelView = [ _instrumentPanelViewController view ];
	
	NSAssert(instrumentPanelView, @"instrumentPanelView");
	
	//

	_mailboxViewController = [ [ SMMailboxViewController alloc ] initWithNibName:@"SMMailboxViewController" bundle:nil ];

	NSAssert(_mailboxViewController, @"_mailboxViewController");
	
	NSView *mailboxView = [ _mailboxViewController view ];

	NSAssert(mailboxView, @"mailboxView");

	//
	
	_searchResultsListViewController = [ [ SMSearchResultsListViewController alloc ] initWithNibName:nil bundle:nil ];
	
	NSAssert(_searchResultsListViewController, @"_searchResultsListViewController");
	
	NSView *searchResultsListView = [ _searchResultsListViewController view ];
	
	NSAssert(searchResultsListView, @"searchResultsListView");

	//

	_messageListViewController = [ [ SMMessageListViewController alloc ] initWithNibName:@"SMMessageListViewController" bundle:nil ];
	
	NSAssert(_messageListViewController, @"_messageListViewController");
		
	NSView *messageListView = [ _messageListViewController view ];

	NSAssert(messageListView, @"messageListView");
	
	//
	
	_messageThreadViewController = [ [ SMMessageThreadViewController alloc ] initWithNibName:nil bundle:nil ];
	
	NSAssert(_messageThreadViewController, @"_messageThreadViewController");
	
	NSView *messageThreadView = [ _messageThreadViewController messageThreadView ];
	
	NSAssert(messageThreadView, @"messageThreadView");

	[messageThreadView setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];

	//
	
	NSSplitView *mailboxAndSearchResultsView = [[NSSplitView alloc] init];
	mailboxAndSearchResultsView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[mailboxAndSearchResultsView setVertical:NO];
	[mailboxAndSearchResultsView setDividerStyle:NSSplitViewDividerStyleThin];
	
	[mailboxAndSearchResultsView addSubview:mailboxView];
	[mailboxAndSearchResultsView addSubview:searchResultsListView];
	
	[mailboxAndSearchResultsView adjustSubviews];
	
	//
	
	[_instrumentPanelViewController.workView addSubview:mailboxAndSearchResultsView];

	[_instrumentPanelViewController.workView addConstraint:
	 [NSLayoutConstraint constraintWithItem:_instrumentPanelViewController.workView
								  attribute:NSLayoutAttributeLeading
								  relatedBy:NSLayoutRelationEqual
									 toItem:mailboxAndSearchResultsView
								  attribute:NSLayoutAttributeLeading
								 multiplier:1
								   constant:0]];

	[_instrumentPanelViewController.workView addConstraint:
	 [NSLayoutConstraint constraintWithItem:_instrumentPanelViewController.workView
								  attribute:NSLayoutAttributeTrailing
								  relatedBy:NSLayoutRelationEqual
									 toItem:mailboxAndSearchResultsView
								  attribute:NSLayoutAttributeTrailing
								 multiplier:1
								   constant:0]];
	
	[_instrumentPanelViewController.workView addConstraint:
	 [NSLayoutConstraint constraintWithItem:_instrumentPanelViewController.workView
								  attribute:NSLayoutAttributeTop
								  relatedBy:NSLayoutRelationEqual
									 toItem:mailboxAndSearchResultsView
								  attribute:NSLayoutAttributeTop
								 multiplier:1
								   constant:0]];
	
	[_instrumentPanelViewController.workView addConstraint:
	 [NSLayoutConstraint constraintWithItem:_instrumentPanelViewController.workView
								  attribute:NSLayoutAttributeBottom
								  relatedBy:NSLayoutRelationEqual
									 toItem:mailboxAndSearchResultsView
								  attribute:NSLayoutAttributeBottom
								 multiplier:1
								   constant:0]];
	
	//
	
	NSSplitView *splitView = [[NSSplitView alloc] init];
	splitView.translatesAutoresizingMaskIntoConstraints = NO;

	[splitView setVertical:YES];
	[splitView setDividerStyle:NSSplitViewDividerStyleThin];
	
	[splitView addSubview:instrumentPanelView];
	[splitView addSubview:messageListView];
	[splitView addSubview:messageThreadView];
	
	[splitView adjustSubviews];

	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-1 forSubviewAtIndex:0];
	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-2 forSubviewAtIndex:1];
	[splitView setHoldingPriority:NSLayoutPriorityDragThatCannotResizeWindow-3 forSubviewAtIndex:2];

	[_view addSubview:splitView];
	
	// 

	[_view addConstraint:[NSLayoutConstraint constraintWithItem:mailboxView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:_view attribute:NSLayoutAttributeHeight multiplier:0.3 constant:0]];

	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
	
	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
	
	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];

	[_view addConstraint:[NSLayoutConstraint constraintWithItem:_view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:splitView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)updateMessageListView {
	Boolean preserveSelection = YES;
	[ _messageListViewController reloadMessageList:preserveSelection ];
}

- (void)updateMailboxFolderListView {
	[ _mailboxViewController updateFolderListView ];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
	// Required delegate method:  Given an item identifier, this method returns an item
	// The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself
	NSToolbarItem *toolbarItem = nil;
	
	if([itemIdent isEqual: SearchDocToolbarItemIdentifier]) {
		// NSToolbarItem doens't normally autovalidate items that hold custom views, but we want this guy to be disabled when there is no text to search.
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdent];
		
/*
 NSMenu *submenu = nil;
		NSMenuItem *submenuItem = nil, *menuFormRep = nil;
*/
		// Set up the standard properties
		[toolbarItem setLabel: @"Search"];
		[toolbarItem setPaletteLabel: @"Search"];
		[toolbarItem setToolTip: @"Search Your Document"];
		
		_searchField = [[NSSearchField alloc] initWithFrame:[_searchField frame]];
		[_searchField.cell setSendsWholeSearchString:YES];

		// Use a custom view, a text field, for the search item
		[toolbarItem setView:_searchField];
		[toolbarItem setMinSize:NSMakeSize(30, NSHeight([_searchField frame]))];
		[toolbarItem setMaxSize:NSMakeSize(400,NSHeight([_searchField frame]))];
		
		// By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a
		// custom menu of your own by using <item> setMenuFormRepresentation]
/*
 submenu = [[[NSMenu alloc] init] autorelease];
		submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
		menuFormRep = [[[NSMenuItem alloc] init] autorelease];
		[submenu addItem: submenuItem];
		[submenuItem setTarget: self];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
 
		// Normally, a menuFormRep with a submenu should just act like a pull down.  However, in 10.4 and later, the menuFormRep can have its own target / action.  If it does, on click and hold (or if the user clicks and drags down), the submenu will appear.  However, on just a click, the menuFormRep will fire its own action.
		[menuFormRep setTarget: self];
		[menuFormRep setAction: @selector(searchMenuFormRepresentationClicked:)];
		
		// Please note, from a user experience perspective, you wouldn't set up your search field and menuFormRep like we do here.  This is simply an example which shows you all of the features you could use.
		[toolbarItem setMenuFormRepresentation: menuFormRep];
 */
	} else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa
		// Returning nil will inform the toolbar this kind of item is not supported
		toolbarItem = nil;
	}
	
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default
	// If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
	// user chooses to revert to the default items this set will be used
	return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, SearchDocToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar
	// does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed
	// The set of allowed items is used to construct the customization palette
	return [NSArray arrayWithObjects:SearchDocToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
	// Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
	// This is the best place to notice a new item is going into the toolbar.  For instance, if you need to
	// cache a reference to the toolbar item or need to set up some initial state, this is the best place
	// to do it.  The notification object is the toolbar to which the item is being added.  The item being
	// added is found by referencing the @"item" key in the userInfo
	NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
	if([[addedItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
		[addedItem setTarget: self];
		[addedItem setAction: @selector(searchUsingToolbarSearchField:)];
		
		_activeSearchItem = addedItem;
	}
}

- (void) searchUsingToolbarSearchField:(id) sender {
	// This message is sent when the user strikes return in the search field in the toolbar
	NSString *searchString = [(NSTextField *)[_activeSearchItem view] stringValue];

	if(searchString.length == 0)
		return;
	
	NSLog(@"%s: searching for string '%@'", __func__, searchString);
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[[appDelegate model] searchResultsListController] startNewSearch:searchString exitingLocalFolder:nil];
}

@end
