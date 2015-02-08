//
//  SMFolderColorController.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/8/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMFolderColorController.h"

@implementation SMFolderColorController {
	NSMutableDictionary *_folderColors;
}

- (id)init {
	self = [super init];
	
	if(self) {
		_folderColors = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

static NSColor *randomColor() {
	CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
	CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
	CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
	NSColor *color = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
	return color;
}

- (NSColor*)colorForFolder:(NSString*)folderName {
	NSColor *color = [_folderColors objectForKey:folderName];

	if(color == nil) {
		color = randomColor();
		
		[_folderColors setObject:color forKey:folderName];
	}
	
	return color;
}

@end
