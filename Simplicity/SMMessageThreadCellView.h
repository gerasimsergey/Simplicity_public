//
//  SMMessageThreadCellView.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/2/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessageViewController;

@interface SMMessageThreadCellView : NSTableCellView

@property IBOutlet NSView *messageView;
@property IBOutlet NSButton *headerButton;

@property SMMessageViewController *messageViewController;

@end
