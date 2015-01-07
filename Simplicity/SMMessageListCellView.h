//
//  SMMessageListCellView.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMMessageListCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *fromTextField;
@property (weak) IBOutlet NSTextField *subjectTextField;
@property (weak) IBOutlet NSTextField *dateTextField;
@property (weak) IBOutlet NSImageView *unseenImage;
@property (weak) IBOutlet NSImageView *starImage;

- (void)initFields;

@end
