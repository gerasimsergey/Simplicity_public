//
//  SMMessageDetailsViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/11/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessage;

@interface SMMessageDetailsViewController : NSViewController

- (void)setMessageDetails:(SMMessage*)message;
- (void)adjustDetailsLayout;

@end
