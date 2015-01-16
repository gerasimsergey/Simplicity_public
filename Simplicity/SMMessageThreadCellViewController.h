//
//  SMMessageThreadCellViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessageBodyViewController;

@interface SMMessageThreadCellViewController : NSViewController

@property (readonly) SMMessageBodyViewController *messageBodyViewController;

- (id)initCollapsed:(Boolean)collapsed;

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder;
- (void)setMessageDetails:(SMMessage*)message;
- (void)updateMessageDetails;

- (void)enableCollapse:(Boolean)enable;

- (void)collapse;
- (void)uncollapse;

@end
