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

@property (readonly) SMMessageThread *currentMessageThread;

- (void)setMessageThread:(SMMessageThread*)messageThread;
- (void)updateMessageThread;

@end
