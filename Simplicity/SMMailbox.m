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

@interface SMMailbox()

- (void)addFolderToMailbox:(NSString*)folder delimiter:(char)delimiter;

@end

@implementation SMMailbox {
	SMFolder *_root;
	NSUInteger _foldersCount;
}

- (id)init {
	self = [ super init ];
	
	if(self) {
		_root = [[ SMFolder alloc ] initWithName:@"ROOT" fullName:@"ROOT"];
		_foldersCount = 0;
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
			
			NSLog(@"Folder '%@', delimiter '%c', flags %ld", pathUtf8, folder.delimiter, folder.flags);
			
			[self addFolderToMailbox:pathUtf8 delimiter:folder.delimiter];
		}
		
	} else {
		NSAssert(nil, @"No folders in mailbox");
	}

	NSLog(@"number of folders %lu", (unsigned long)_foldersCount);
}

- (SMFolder*)root {
	return _root;
}
	
- (void)addFolderToMailbox:(NSString*)folderFullName delimiter:(char)delimiter {
	SMFolder *curFolder = _root;
	
	NSArray *tokens = [ folderFullName componentsSeparatedByString:[NSString stringWithFormat:@"%c", delimiter]];
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
			for(; i < [tokens count]; i++) {
				curFolder = [curFolder addSubfolder:token fullName:currentFullName];
				_foldersCount++;
			}
			
			break;
		}
	}
}

@end
