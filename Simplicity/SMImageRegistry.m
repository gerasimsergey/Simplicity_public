//
//  SMImageRegistry.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/10/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMImageRegistry.h"

@implementation SMImageRegistry

- (id)init {
	self = [super init];
	
	if(self) {
		_attachmentImage = [NSImage imageNamed:@"attachment-icon.png"];
		_attachmentDocumentImage = [NSImage imageNamed:@"attachment-document.png"];
		_blueCircleImage = [NSImage imageNamed:@"circle-blue.png"];
		_yellowStarImage = [NSImage imageNamed:@"star-yellow-icon.png"];
		_grayStarImage = [NSImage imageNamed:@"star-gray-icon.png"];
		_infoImage = [NSImage imageNamed:@"info-icon.png"];
	}
	
	return self;
}

@end
