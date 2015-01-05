//
//  SMMessageViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 7/31/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

@class SMMessageDetailsViewController;
@class SMMessageBodyViewController;
@class SMMessage;

@interface SMMessageViewController : NSViewController

@property (readonly) SMMessageBodyViewController *messageBodyViewController;

- (void)collapseHeader;
- (void)uncollapseHeader;

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder;
- (void)setMessageDetails:(SMMessage*)message;

@end
