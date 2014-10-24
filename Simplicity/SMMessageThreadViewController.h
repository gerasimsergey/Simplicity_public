//
//  SMMessageThreadViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/2/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessageThread;

@interface SMMessageThreadViewController : NSViewController

@property NSScrollView *messageThreadView;

- (void)setMessageThread:(SMMessageThread*)messageThread;
- (SMMessageThread*)currentMessageThread;

@end
