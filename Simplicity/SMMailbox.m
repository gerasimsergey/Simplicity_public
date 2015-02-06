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
	NSMutableArray *_favoriteFolders;
	NSMutableArray *_folders;
}

- (id)init {
	self = [ super init ];
	
	if(self) {
		_rootFolder = [[SMFolder alloc] initWithName:@"ROOT" fullName:@"ROOT" flags:MCOIMAPFolderFlagNone];
		_mainFolders = [NSMutableArray array];
		_favoriteFolders = [NSMutableArray array];
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
				curFolder = [curFolder addSubfolder:token fullName:currentFullName flags:flags];
			
			break;
		}
	}
	
	// build flat structure
	// TODO: optimize?
	[_folders removeAllObjects];
	
	NSAssert(_rootFolder.subfolders.count > 0, @"root folder is empty");

	for(SMFolder *subfolder in _rootFolder.subfolders)
		[self dfs:subfolder];
}

- (void)updateMainFolders {
	[_mainFolders removeAllObjects];
	
	[self addMainFolderWithFlags:MCOIMAPFolderFlagInbox orName:@"INBOX" as:@"INBOX"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagImportant orName:nil as:@"Important"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagSentMail orName:nil as:@"Sent"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagDrafts orName:nil as:@"Drafts"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagStarred orName:nil as:@"Starred"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagSpam orName:nil as:@"Spam"];
	[self addMainFolderWithFlags:MCOIMAPFolderFlagTrash orName:nil as:@"Trash"];
}

- (void)addMainFolderWithFlags:(MCOIMAPFolderFlag)flags orName:(NSString*)name as:(NSString*)displayName {
	for(NSUInteger i = 0; i < _folders.count; i++) {
		SMFolder *folder = _folders[i];
		
		if((folder.flags & flags) || (name != nil && [folder.fullName compare:name] == NSOrderedSame)) {
			folder.displayName = displayName;

			[_folders removeObjectAtIndex:i];
			[_mainFolders addObject:folder];

			break;
		}
	}
}

- (void)updateFavoriteFolders {
	[_favoriteFolders removeAllObjects];
	
	[self addFavoriteFolderWithName:@"Work/CVC/DVBS"];
	[self addFavoriteFolderWithName:@"Work/Charter"];
}

- (void)addFavoriteFolderWithName:(NSString*)name {
	for(NSUInteger i = 0; i < _folders.count; i++) {
		SMFolder *folder = _folders[i];

		if([folder.fullName compare:name] == NSOrderedSame) {
			[_favoriteFolders addObject:folder];
			
			break;
		}
	}
}

@end
