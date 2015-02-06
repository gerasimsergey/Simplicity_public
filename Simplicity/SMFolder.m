//
//  SMFolder.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/23/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMFolder.h"

@implementation SMFolder {
	NSString *_shortName;
	NSString *_fullName;
	NSString *_displayName;
	NSMutableArray *_subfolders;
}

static NSColor *randomColor() {
	CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
	CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
	CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
	NSColor *color = [NSColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
	return color;
}

- (id)initWithName:(NSString*)shortName fullName:(NSString*)fullName flags:(MCOIMAPFolderFlag)flags {
	self = [ super init ];
	
	if(self) {
		_subfolders = [NSMutableArray new];
		_shortName = shortName;
		_fullName = fullName;
		_flags = flags;
		_color = randomColor();
	}
	
	return self;
}

- (NSArray*)subfolders {
	return _subfolders;
}

- (SMFolder*)addSubfolder:(NSString*)shortName fullName:(NSString*)fullName flags:(MCOIMAPFolderFlag)flags {
	SMFolder *folder = [[SMFolder alloc] initWithName:shortName fullName:fullName flags:flags];
	
	[_subfolders addObject:folder];
	
	return folder;
}

- (void)setDisplayName:(NSString *)displayName {
	_displayName = displayName;
}

- (NSString *)displayName {
	return _displayName != nil? _displayName : _fullName;
}

@end
