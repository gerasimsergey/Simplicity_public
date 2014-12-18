//
//  SMLocalFolderRegistry.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/22/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMSimplicityContainer.h"
#import "SMMessageStorage.h"
#import "SMLocalFolder.h"
#import "SMLocalFolderRegistry.h"

@implementation SMLocalFolderRegistry {
	NSMutableDictionary *_folders;	
}

- (id)init {
	self = [ super init ];
	
	if(self) {
		_folders = [NSMutableDictionary new];
	}
	
	return self;
}

- (SMLocalFolder*)getLocalFolder:(NSString*)folderName {
	return [_folders objectForKey:folderName];
}

- (SMLocalFolder*)getOrCreateLocalFolder:localFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder {
	SMLocalFolder *folder = [_folders objectForKey:localFolderName];
	
	if(folder == nil) {
		folder = [[SMLocalFolder alloc] initWithLocalFolderName:localFolderName syncWithRemoteFolder:syncWithRemoteFolder];
		[_folders setValue:folder forKey:localFolderName];
	}
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[[appDelegate model] messageStorage] ensureLocalFolderExists:localFolderName];
	
	return folder;
}

- (void)removeLocalFolder:(NSString*)folderName {
	SMLocalFolder *localFolder = [_folders objectForKey:folderName];
	[localFolder stopMessagesLoading:YES];

	[_folders removeObjectForKey:folderName];
}

@end
