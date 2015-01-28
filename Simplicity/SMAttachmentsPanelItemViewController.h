//
//  SMAttachmentsPanelItemView.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMTrackingBox;

@interface SMAttachmentsPanelItemViewController : NSCollectionViewItem

@property IBOutlet NSBox *box;
@property IBOutlet NSBox *dimBox;
@property IBOutlet NSTextField *fileNameField;

@end
