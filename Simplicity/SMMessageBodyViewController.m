//
//  SMMessageViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/25/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WebKit/WebView.h>
#import <WebKit/WebFrame.h>
#import <WebKit/WebFrameView.h>
#import <WebKit/WebDataSource.h>
#import <WebKit/WebPolicyDelegate.h>

#import "SMMessageBodyViewController.h"
#import "SMAppDelegate.h"
#import "SMAttachmentStorage.h"

@interface SMMessageBodyViewController (WebResourceLoadDelegate)

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource;

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource;

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource;

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource;

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveContentLength:(NSUInteger)length fromDataSource:(WebDataSource *)dataSource;

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource;

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener;

@end

@implementation SMMessageBodyViewController {
	unsigned long long _nextIdentifier;
	WebView *_view;
	NSString *_htmlText;
	uint32_t _uid;
	NSString *_folder;
	Boolean _uncollapsed;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_view = [[WebView alloc] init];
		
		_view.translatesAutoresizingMaskIntoConstraints = NO;
		
		[_view setPolicyDelegate:self];
		[_view setResourceLoadDelegate:self];
		[_view setMaintainsBackForwardList:NO];
		[_view setCanDrawConcurrently:YES];
		[_view setEditable:NO];
		
		[self setView:_view];
		
		_nextIdentifier = 0;
	}
	
	return self;
}

- (void)loadHTML {
	NSAssert(_uncollapsed, @"view is collapsed");

	[[_view mainFrame] loadHTMLString:_htmlText baseURL:nil];
}

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder {
	[_view stopLoading:self];
	
	_htmlText = htmlText;
	_uid = uid;
	_folder = folder;
	
	if(_uncollapsed) {
		[self loadHTML];
	}
}

- (void)uncollapse {
	if(!_uncollapsed) {
		_uncollapsed = YES;
		[self loadHTML];
	}
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
//	NSLog(@"%s: request %@, identifier %llu", __FUNCTION__, request, _nextIdentifier);
	return [NSNumber numberWithUnsignedLongLong:_nextIdentifier++];
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	
//	NSLog(@"%s: request %@, identifier %@", __FUNCTION__, request, identifier);
	
	NSURL *url = [request URL];
	NSString *absoluteUrl = [url absoluteString];
	
//	NSLog(@"%s: url absoluteString: %@", __FUNCTION__, absoluteUrl);
	
	////
//	NSScrollView *scrollView = [[[[_view mainFrame] frameView] documentView] enclosingScrollView];
//	NSRect scrollViewBounds = [[scrollView contentView] bounds];
//	NSPoint savedScrollPosition = scrollViewBounds.origin;
//	NSSize savedScrollSize = scrollViewBounds.size;
//	NSLog(@"Current scroll position: %f, %f\n", savedScrollPosition.x, savedScrollPosition.y);
//	NSLog(@"Current scroll size: %f, %f\n", savedScrollSize.width, savedScrollSize.height);
	////
	
	if([absoluteUrl hasPrefix:@"cid:"]) {
		// TODO: handle not completely downloaded attachments
		// TODO: implement a precise contentId matching (to handle the really existing imap parts)
		NSString *contentId = [absoluteUrl substringFromIndex:4];
		
		SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
		NSURL *attachmentLocation = [[[appDelegate model] attachmentStorage] attachmentLocation:contentId uid:_uid folder:_folder];
		
		if(!attachmentLocation) {
			NSLog(@"%s: cannot load attachment for contentId %@", __FUNCTION__, contentId);
			return request;
		}
		
//		NSLog(@"%s: loading attachment file '%@' for contentId %@", __FUNCTION__, attachmentLocation, contentId);
		return [NSURLRequest requestWithURL:attachmentLocation];
	}
	
	return request;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource {
//	NSLog(@"%s: identifier %@", __FUNCTION__, identifier);
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource {
//	NSLog(@"%s: identifier %@", __FUNCTION__, identifier);
}

- (void)webView:(WebView *)sender resource:(id)identifier didReceiveContentLength:(NSUInteger)length fromDataSource:(WebDataSource *)dataSource {
//	NSLog(@"%s: identifier %@", __FUNCTION__, identifier);
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
//	NSLog(@"%s: identifier %@", __FUNCTION__, identifier);
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
	if ([actionInformation objectForKey:WebActionElementKey]) {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	} else {
		[listener use];
	}
}

@end
