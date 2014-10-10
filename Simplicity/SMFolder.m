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
	NSMutableArray *_subfolders;
}

- (id)initWithName:(NSString*)shortName fullName:(NSString*)fullName {
	self = [ super init ];
	
	if(self) {
		_subfolders = [NSMutableArray new];
		_shortName = shortName;
		_fullName = fullName;
	}
	
	return self;
}

- (NSArray*)subfolders {
	return _subfolders;
}

- (SMFolder*)addSubfolder:(NSString*)shortName fullName:(NSString*)fullName {
	SMFolder *folder = [[SMFolder alloc] initWithName:shortName fullName:fullName];
	
	[_subfolders addObject:folder];
	
	return folder;
}

@end
