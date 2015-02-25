//
//  SMMessageThreadCellViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessage.h"
#import "SMMessageDetailsViewController.h"
#import "SMMessageBodyViewController.h"
#import "SMAttachmentItem.h"
#import "SMAttachmentsPanelViewController.h"
#import "SMMessageThreadCellViewController.h"

@implementation SMMessageThreadCellViewController {
	SMMessage *_message;
	SMMessageDetailsViewController *_messageDetailsViewController;
	SMMessageBodyViewController *_messageBodyViewController;
	SMAttachmentsPanelViewController *_attachmentsPanelViewController;

	NSView *_messageView;
	NSButton *_headerButton;
	NSProgressIndicator *_progressIndicator;
	NSLayoutConstraint *_heightConstraint;
	NSLayoutConstraint *_messageDetailsBottomConstraint;
	NSLayoutConstraint *_messageBodyBottomConstraint;
	NSMutableArray *_attachmentsPanelViewConstraints;
	CGFloat _messageViewHeight;
	Boolean _collapsed;
	NSString *_htmlText;
	Boolean _messageTextIsSet;
	Boolean _attachmentsPanelShown;
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
		[view setCornerRadius:0];
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

		// init message details view
		
		_messageDetailsViewController = [[SMMessageDetailsViewController alloc] init];
		
		NSView *messageDetailsView = [ _messageDetailsViewController view ];
		NSAssert(messageDetailsView, @"messageDetailsView");
		
		[view addSubview:messageDetailsView];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0] priority:NSLayoutPriorityDefaultLow];
		
		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:messageDetailsView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0] priority:NSLayoutPriorityRequired];
	
		_messageDetailsBottomConstraint = [NSLayoutConstraint constraintWithItem:messageDetailsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];

		[_messageDetailsViewController setEnclosingThreadCell:self];
		
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
	
	[self hideAttachmentsPanel];

	[_messageDetailsViewController collapse];

	NSBox *view = (NSBox*)[self view];
	NSAssert(view != nil, @"view is nil");
	
	[view setFillColor:[NSColor colorWithCalibratedRed:0.96 green:0.96 blue:0.96 alpha:1.0]];

	if(_heightConstraint == nil) {
		_heightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:[SMMessageDetailsViewController headerHeight]];
		
		_heightConstraint.priority = NSLayoutPriorityRequired;
	}
	
	[view addConstraint:_heightConstraint];
	
	[_progressIndicator setHidden:YES];
	
	_collapsed = YES;
}

- (void)uncollapse {
	if(!_collapsed)
		return;

	NSBox *view = (NSBox*)[self view];
	NSAssert(view != nil, @"view is nil");
	
	if(_messageBodyViewController == nil) {
		[view removeConstraint:_messageDetailsBottomConstraint];

		_messageBodyViewController = [[SMMessageBodyViewController alloc] init];
		
		NSView *messageBodyView = [_messageBodyViewController view];
		NSAssert(messageBodyView, @"messageBodyView");
		
		[view addSubview:messageBodyView];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:_messageDetailsViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:messageBodyView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];

		[self addConstraint:view constraint:[NSLayoutConstraint constraintWithItem:messageBodyView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:0 multiplier:1.0 constant:300] priority:NSLayoutPriorityDefaultLow];
		
		NSAssert(_messageBodyBottomConstraint == nil, @"_messageBodyBottomConstraint already created");
		_messageBodyBottomConstraint = [NSLayoutConstraint constraintWithItem:messageBodyView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];

		[view addConstraint:_messageBodyBottomConstraint];

		if(_htmlText != nil) {
			// this means that the message html text was set before,
			// when there was no body view
			// so show it now
			[self showMessageBody];
		}
	}
	
	[view setFillColor:[NSColor whiteColor]];
	
	[_messageDetailsViewController uncollapse];
	[_messageBodyViewController uncollapse];

	if(_heightConstraint != nil) {
		[[self view] removeConstraint:_heightConstraint];
	}
	
	if(_htmlText == nil) {
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

- (void)toggleAttachmentsPanel {
	if(!_attachmentsPanelShown)
	{
		[self showAttachmentsPanel];
	}
	else
	{
		[self hideAttachmentsPanel];
	}
}

- (void)showAttachmentsPanel {
	if(_attachmentsPanelShown)
		return;

	NSView *view = [self view];
	NSAssert(view != nil, @"view is nil");

	NSAssert(_messageBodyBottomConstraint != nil, @"_messageBodyBottomConstraint not created");
	[view removeConstraint:_messageBodyBottomConstraint];
	
	if(_attachmentsPanelViewController == nil) {
		_attachmentsPanelViewController = [[SMAttachmentsPanelViewController alloc] initWithNibName:@"SMAttachmentsPanelViewController" bundle:nil];
		
		NSView *attachmentsView = _attachmentsPanelViewController.view;
		NSAssert(attachmentsView, @"attachmentsView");
		
		NSAssert(_attachmentsPanelViewConstraints == nil, @"_attachmentsPanelViewConstraints already created");
		_attachmentsPanelViewConstraints = [NSMutableArray array];
		
		[_attachmentsPanelViewConstraints addObject:[NSLayoutConstraint constraintWithItem:_messageBodyViewController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:attachmentsView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
		
		[_attachmentsPanelViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:attachmentsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
		
		[_attachmentsPanelViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:attachmentsView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
		
		[_attachmentsPanelViewConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:attachmentsView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
		
		// test adding objects to the attachment panel

		NSAssert(_message.attachments.count > 0, @"message has no attachments, the panel should never be shown");
		
		NSArrayController *arrayController = _attachmentsPanelViewController.arrayController;
		
		for(NSUInteger i = 0; i < _message.attachments.count; i++)
			[arrayController addObject:[[SMAttachmentItem alloc] initWithMessage:_message attachmentIndex:i]];
		
		[arrayController setSelectedObjects:[NSArray array]];
	}

	[view addSubview:_attachmentsPanelViewController.view];
	[view addConstraints:_attachmentsPanelViewConstraints];

	_attachmentsPanelShown = YES;
}

- (void)hideAttachmentsPanel {
	if(!_attachmentsPanelShown)
		return;

	NSView *view = [self view];
	NSAssert(view != nil, @"view is nil");

	NSAssert(_attachmentsPanelViewConstraints != nil, @"_attachmentsPanelViewConstraints not created");
	[view removeConstraints:_attachmentsPanelViewConstraints];

	[_attachmentsPanelViewController.view removeFromSuperview];

	NSAssert(_messageBodyBottomConstraint != nil, @"_messageBodyBottomConstraint not created");
	[view addConstraint:_messageBodyBottomConstraint];

	_attachmentsPanelShown = NO;
}

- (void)showMessageBody {
	NSAssert(_messageBodyViewController != nil, @"not message body view controller");
		
	NSView *messageBodyView = [_messageBodyViewController view];
	NSAssert(messageBodyView, @"messageBodyView");
	
	[_messageBodyViewController setMessageViewText:_htmlText uid:_message.uid folder:[_message remoteFolder]];
	
	[_progressIndicator stopAnimation:self];
}

- (Boolean)loadMessageBody {
	NSAssert(_message != nil, @"no message set");

	if(_htmlText != nil)
		return TRUE;

	_htmlText = [_message htmlBodyRendering];
	
	if(_htmlText == nil)
		return FALSE;

	if(_messageBodyViewController != nil)
		[self showMessageBody];

	_messageTextIsSet = YES;
	
	return TRUE;
}

- (void)setMessage:(SMMessage*)message {
	NSAssert(_message == nil, @"message already set");

	_message = message;

	[_messageDetailsViewController setMessage:message];
}

- (void)updateMessage {
	[_messageDetailsViewController updateMessage];
}

#pragma mark Finding contents

- (NSUInteger)highlightAllOccurrencesOfString:(NSString*)str matchCase:(Boolean)matchCase {
	return [_messageBodyViewController highlightAllOccurrencesOfString:str matchCase:matchCase];
}

- (void)markOccurrenceOfFoundString:(NSUInteger)index {
	[_messageBodyViewController markOccurrenceOfFoundString:index];
}

- (void)removeMarkedOccurrenceOfFoundString {
	[_messageBodyViewController removeMarkedOccurrenceOfFoundString];
}

- (void)removeAllHighlightedOccurrencesOfString {
	[_messageBodyViewController removeAllHighlightedOccurrencesOfString];
}

@end
