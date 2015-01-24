//
//  SMAttachmentsPanelItemView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/24/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsPanelItemView.h"

@implementation SMAttachmentsPanelItemView

- (void) awakeFromNib {
	NSBox *view = (NSBox*) [self view];
	[view setTitlePosition:NSNoTitle];
	[view setBoxType:NSBoxCustom];
	[view setCornerRadius:8.0];
	[view setBorderType:NSLineBorder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
