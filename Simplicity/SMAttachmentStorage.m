//
//  SMMessageAttachmentStorage.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/29/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMAttachmentStorage.h"
#import "SMAppDelegate.h"

@interface SMAttachmentStorage()

- (NSURL*)attachmentDirectoryForFolder:(NSString *)folder uid:(uint32_t)uid contentId:(NSString *)contentId;

@end

@implementation SMAttachmentStorage

- (void)storeAttachment:(NSData *)data folder:(NSString *)folder uid:(uint32_t)uid contentId:(NSString *)contentId {
	NSAssert(data, @"bad data");
	
	NSURL *attachmentDir = [self attachmentDirectoryForFolder:folder uid:uid contentId:contentId];
	
	if(![self createDirectory:attachmentDir]) {
		NSLog(@"%s: cannot create directory '%@' for attachment '%@'", __FUNCTION__, [attachmentDir path], contentId);
		
		return;
	}

	NSURL *attachmentFile = [attachmentDir URLByAppendingPathComponent:contentId];
	NSString *attachmentFilePath = [attachmentFile path];
	
	if(![data writeToFile:attachmentFilePath atomically:YES]) {
		NSLog(@"%s: cannot write file '%@' (%lu bytes)", __FUNCTION__, attachmentFilePath, (unsigned long)[data length]);
	} else {
		NSLog(@"%s: file %@ (%lu bytes) written successfully", __FUNCTION__, attachmentFilePath, (unsigned long)[data length]);
	}
}

- (NSURL*)attachmentLocation:(NSString*)contentId uid:(uint32_t)uid folder:(NSString*)folder {
	NSAssert(contentId != nil, @"contentId is nil");
	
	NSURL *attachmentDir = [self attachmentDirectoryForFolder:folder uid:uid contentId:contentId];
	NSURL *attachmentFile = [attachmentDir URLByAppendingPathComponent:contentId];

	return attachmentFile;
}

- (NSURL*)attachmentDirectoryForFolder:(NSString *)folder uid:(uint32_t)uid contentId:(NSString *)contentId {
	NSURL* appDataDir = [SMAppDelegate appDataDir];
	
	NSAssert(appDataDir, @"no app data dir");
	
	return [[appDataDir URLByAppendingPathComponent:folder isDirectory:YES] URLByAppendingPathComponent:[[NSNumber numberWithInt:uid] stringValue] isDirectory:YES];
}

- (BOOL)createDirectory:(NSURL*)dir {
	NSString *dirPath = [dir path];
	
	NSFileManager *fileManager= [NSFileManager defaultManager];
	NSError *error = nil;

	if(![fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"%s: failed to create directory '%@', error: %@", __FUNCTION__, dirPath, error);
		return NO;
	}

	NSLog(@"%s: directory '%@' created successfully", __FUNCTION__, dirPath);
	return YES;
}

@end
