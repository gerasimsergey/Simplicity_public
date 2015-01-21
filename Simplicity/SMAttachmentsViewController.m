//
//  SMAttachmentsViewController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/20/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentsViewController.h"

@implementation SMAttachmentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if(self) {
		_attachmentItems = [[NSMutableArray alloc] init];
	}
	
	return self;
}

@end
