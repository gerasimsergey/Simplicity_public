//
//  SMAttachmentsViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/20/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMAttachmentsViewController : NSViewController

@property IBOutlet NSArrayController *arrayController;

@property NSMutableArray *attachmentItems;

@end
