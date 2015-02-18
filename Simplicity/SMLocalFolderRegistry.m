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

@interface FolderEntry : NSObject
@property (readonly) SMLocalFolder *folder;
@property (readonly) NSTimeInterval timestamp;
- (id)initWithFolder:(SMLocalFolder*)folder;
- (void)updateTimestamp;
@end

@implementation FolderEntry
- (id)initWithFolder:(SMLocalFolder*)folder {
	self = [super init];
	if(self) {
		_folder = folder;
		_timestamp = [[NSDate date] timeIntervalSince1970];
	}
	return self;
}
- (void)updateTimestamp {
	_timestamp = [[NSDate date] timeIntervalSince1970];
}
@end

@implementation SMLocalFolderRegistry {
	NSMutableDictionary *_folders;
	NSMutableOrderedSet *_accessTimeSortedFolders;
	NSComparator _accessTimeFolderComparator;
}

- (id)init {
	self = [super init];
	
	if(self) {
		_folders = [NSMutableDictionary new];
		_accessTimeSortedFolders = [NSMutableOrderedSet new];
		_accessTimeFolderComparator = ^NSComparisonResult(id a, id b) {
			FolderEntry *f1 = (FolderEntry*)a;
			FolderEntry *f2 = (FolderEntry*)b;
			
			return f1.timestamp < f2.timestamp? NSOrderedAscending : (f1.timestamp > f2.timestamp? NSOrderedDescending : NSOrderedSame);
		};
	}
	
	return self;
}

- (void)updateFolderEntryAccessTime:(FolderEntry*)folderEntry {
	[_accessTimeSortedFolders removeObjectAtIndex:[self getFolderEntryIndex:folderEntry]];
	
	[folderEntry updateTimestamp];

	[_accessTimeSortedFolders insertObject:folderEntry atIndex:[self getFolderEntryIndex:folderEntry]];
}

- (SMLocalFolder*)getLocalFolder:(NSString*)folderName {
	FolderEntry *folderEntry = [_folders objectForKey:folderName];
	
	[self updateFolderEntryAccessTime:folderEntry];
	
	return folderEntry.folder;
}

- (NSUInteger)getFolderEntryIndex:(FolderEntry*)folderEntry {
	return [_accessTimeSortedFolders indexOfObject:folderEntry inSortedRange:NSMakeRange(0, _accessTimeSortedFolders.count) options:NSBinarySearchingInsertionIndex usingComparator:_accessTimeFolderComparator];
}

- (SMLocalFolder*)getOrCreateLocalFolder:localFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder {
	FolderEntry *folderEntry = [_folders objectForKey:localFolderName];
	
	if(folderEntry == nil) {
		SMLocalFolder *folder = [[SMLocalFolder alloc] initWithLocalFolderName:localFolderName syncWithRemoteFolder:syncWithRemoteFolder];

		folderEntry = [[FolderEntry alloc] initWithFolder:folder];

		[folderEntry updateTimestamp];

		[_folders setValue:folderEntry forKey:localFolderName];

		[_accessTimeSortedFolders insertObject:folderEntry atIndex:[self getFolderEntryIndex:folderEntry]];
	} else {
		[self updateFolderEntryAccessTime:folderEntry];
	}
	
	SMAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
	[[[appDelegate model] messageStorage] ensureLocalFolderExists:localFolderName];
	
	return folderEntry.folder;
}

- (void)removeLocalFolder:(NSString*)folderName {
	FolderEntry *folderEntry = [_folders objectForKey:folderName];
	[folderEntry.folder stopMessagesLoading:YES];

	[_folders removeObjectForKey:folderName];

	[_accessTimeSortedFolders removeObjectAtIndex:[self getFolderEntryIndex:folderEntry]];
}

@end
