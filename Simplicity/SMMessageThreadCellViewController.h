//
//  SMMessageThreadCellViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessageViewController;

@interface SMMessageThreadCellViewController : NSViewController

@property SMMessageViewController *messageViewController;

- (id)initCollapsed:(Boolean)collapsed;

- (void)setMessageViewText:(NSString*)htmlText uid:(uint32_t)uid folder:(NSString*)folder;

- (void)enableCollapse:(Boolean)enable;

- (void)collapse;
- (void)uncollapse;

@end
