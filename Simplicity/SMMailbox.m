//
//  SMFolderTree.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/22/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#include <CoreFoundation/CFStringEncodingExt.h>

#import <MailCore/MailCore.h>

#import "SMMailbox.h"
#import "SMFolder.h"

@implementation SMMailbox {
	NSMutableArray *_mainFolders;
	NSMutableOrderedSet *_favoriteFolders;
	NSMutableArray *_folders;
}

- (id)init {
	self = [ super init ];
	
	if(self) {
		_rootFolder = [[SMFolder alloc] initWithName:@"ROOT" fullName:@"ROOT" delimiter:'/' flags:MCOIMAPFolderFlagNone];
		_mainFolders = [NSMutableArray array];
		_favoriteFolders = [[NSMutableOrderedSet alloc] init];
		_folders = [NSMutableArray array];
	}

	return self;
}

- (void)updateIMAPFolders:(NSArray *)folders {
	
	if([folders count] > 0) {
/*
 NSMutableArray *sortedFolders = [NSMutableArray new];
MCOIMAPFolder *firstFolder = (MCOIMAPFolder*)[folders firstObject];
		
		for(MCOIMAPFolder *folder in folders) {
			NSString *path = folder.path;
			NSData *pathData = [path dataUsingEncoding:NSUTF8StringEncoding];
			NSString *pathUtf8 = (__bridge NSString *)CFStringCreateWithBytes(NULL, [pathData bytes], [pathData length], kCFStringEncodingUTF7_IMAP, YES);
			
			NSLog(@"Folder '%@', delimiter '%c', flags %u", pathUtf8, folder.delimiter, folder.flags);
			
			NSAssert(folder.delimiter == firstFolder.delimiter, @"Different delimiters");
			
			[sortedFolders addObject:pathUtf8];
		}
		
		[sortedFolders sortUsingComparator:^(NSString *f1, NSString *f2){
			return [f1 compare:f2];
		}];
*/
		for(MCOIMAPFolder *folder in folders) {
			NSString *path = folder.path;
			NSData *pathData = [path dataUsingEncoding:NSUTF8StringEncoding];
			NSString *pathUtf8 = (__bridge NSString *)CFStringCreateWithBytes(NULL, [pathData bytes], [pathData length], kCFStringEncodingUTF7_IMAP, YES);
			
//			NSLog(@"Folder '%@', delimiter '%c', flags %ld", pathUtf8, folder.delimiter, folder.flags);
			
			[self addFolderToMailbox:pathUtf8 delimiter:folder.delimiter flags:folder.flags];
		}

		[self updateMainFolders];
		[self updateFavoriteFolders];
	} else {
		NSAssert(nil, @"No folders in mailbox");
	}

//	NSLog(@"number of folders %lu", _folders.count);
}

- (void)dfs:(SMFolder *)folder {
	[_folders addObject:folder];
	
	for(SMFolder *subfolder in folder.subfolders)
		[self dfs:subfolder];
}

- (void)addFolderToMailbox:(NSString*)folderFullName delimiter:(char)delimiter flags:(MCOIMAPFolderFlag)flags {
	SMFolder *curFolder = _rootFolder;
	
	NSArray *tokens = [folderFullName componentsSeparatedByString:[NSString stringWithFormat:@"%c", delimiter]];
	NSMutableString *currentFullName = [NSMutableString new];
	
	for(NSUInteger i = 0; i < [tokens count]; i++) {
		NSString *token = tokens[i];

		if(i > 0)
			[currentFullName appendFormat:@"%c", delimiter];
		
		[currentFullName appendString:token];
		
		Boolean found = NO;
		
		for(SMFolder *f in [curFolder subfolders]) {
			if([token compare:[f shortName]] == NSOrderedSame) {
				curFolder = f;
				found = YES;
				break;
			}
		}

		if(!found) {
			for(; i < [tokens count]; i++)
				curFolder = [curFolder addSubfolder:token fullName:currentFullName delimiter:delimiter flags:flags];
			
			break;
		}
	}
	
	// build flat structure

	// TODO: currently the flat structure is rebuilt on each folder addition
	//       instead, it should be constructed iteratively
	[_folders removeAllObjects];
	
	NSAssert(_rootFolder.subfolders.count > 0, @"root folder is empty");

	for(SMFolder *subfolder in _rootFolder.subfolders)
		[self dfs:subfolder];
}

- (void)updateMainFolders {
	[_mainFolders removeAllObjects];
	
	[self addMainFolderWithFlags:MCOIMAPFolderFlagInbox orName:@"INBOX" as:@"INBOX" setKind:SMFolderKindInbox];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagImportant orName:nil as:@"Important" setKind:SMFolderKindImportant];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagSentMail orName:nil as:@"Sent" setKind:SMFolderKindSent];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagDrafts orName:nil as:@"Drafts" setKind:SMFolderKindDrafts];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagStarred orName:nil as:@"Starred" setKind:SMFolderKindStarred];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagSpam orName:nil as:@"Spam" setKind:SMFolderKindSpam];

	_trashFolder = [self addMainFolderWithFlags:MCOIMAPFolderFlagTrash orName:nil as:@"Trash" setKind:SMFolderKindTrash];
	_allMailFolder = [self addMainFolderWithFlags:MCOIMAPFolderFlagAllMail orName:nil as:@"All Mail" setKind:SMFolderKindAllMail];
}

- (SMFolder*)addMainFolderWithFlags:(MCOIMAPFolderFlag)flags orName:(NSString*)name as:(NSString*)displayName setKind:(SMFolderKind)kind {
	for(NSUInteger i = 0; i < _folders.count; i++) {
		SMFolder *folder = _folders[i];
		
		if((folder.flags & flags) || (name != nil && [folder.fullName compare:name] == NSOrderedSame)) {
			folder.displayName = displayName;
			folder.kind = kind;

			[_folders removeObjectAtIndex:i];
			[_mainFolders addObject:folder];

			return folder;
		}
	}
	
	return nil;
}

- (void)sortFavorites {
	[_favoriteFolders sortUsingComparator:^NSComparisonResult(SMFolder *f1, SMFolder *f2) {
		return [f1.fullName compare:f2.fullName];
	}];
}

- (void)updateFavoriteFolders {
	static Boolean firstTime = YES;
	if(firstTime) {
		// TODO: remove
		[self addFavoriteFolderWithName:@"Work/CVC/DVBS"];
		[self addFavoriteFolderWithName:@"Private/Misc"];
		[self addFavoriteFolderWithName:@"Work/Charter"];
		firstTime = NO;
	}

	for(SMFolder *folder in _folders) {
		if(folder.favorite) {
			[_favoriteFolders addObject:folder];
		} else {
			[_favoriteFolders removeObject:folder];
		}
	}

	[self sortFavorites];
}

- (void)addFavoriteFolderWithName:(NSString*)name {
	for(NSUInteger i = 0; i < _folders.count; i++) {
		SMFolder *folder = _folders[i];

		if(!folder.favorite && [folder.fullName compare:name] == NSOrderedSame) {
			folder.favorite = YES;

			[_favoriteFolders addObject:folder];

			[self sortFavorites];

			break;
		}
	}
}

- (void)removeFavoriteFolderWithName:(NSString*)name {
	for(NSUInteger i = 0; i < _folders.count; i++) {
		SMFolder *folder = _folders[i];

		if([folder.fullName compare:name] == NSOrderedSame) {
			NSAssert(folder.favorite, @"folder %@ is not favorite", name);

			folder.favorite = NO;

			[_favoriteFolders removeObject:folder];
			
			break;
		}
	}
}

- (SMFolder*)getFolderByName:(NSString*)folderName {
	for(SMFolder *f in _folders) {
		if([f.fullName isEqualToString:folderName])
			return f;
	}

	for(SMFolder *f in _mainFolders) {
		if([f.fullName isEqualToString:folderName])
			return f;
	}
	
	return nil;
}

- (NSString*)constructFolderName:(NSString*)folderName parent:(NSString*)parentFolderName {
	NSAssert(folderName != nil && folderName.length > 0, @"bad folder name");

	if(parentFolderName != nil) {
		SMFolder *parentFolder = [self getFolderByName:parentFolderName];
		NSAssert(parentFolder != nil, @"parentFolder (name %@) is nil", parentFolderName);

		return [parentFolderName stringByAppendingFormat:@"%c%@", parentFolder.delimiter, folderName];
	} else {
		return folderName;
	}
}

@end
