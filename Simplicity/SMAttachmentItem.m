//
//  SMAttachmentItem.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentItem.h"

@implementation SMAttachmentItem

- (id)initWithFileName:(NSString*)fileName {
	self = [super init];
	
	if(self) {
		_fileName = fileName;
	}
	
	return self;
}

@end
