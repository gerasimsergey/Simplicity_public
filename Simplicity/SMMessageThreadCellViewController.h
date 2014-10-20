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

@property NSView *messageView;
@property NSButton *headerButton;

@property SMMessageViewController *messageViewController;

- (void)enableCollapse;

@end
