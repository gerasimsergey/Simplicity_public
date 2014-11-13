//
//  SMLocalFolder.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/9/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMLocalFolder : NSObject

@property NSString* name;

- (id)initWithLocalFolderName:(NSString*)localFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder;

// these two methods are used to sync the content of this folder
// with the remote folder with the same name
- (void)startRemoteFolderSync;
- (void)stopRemoteFolderSync;

// loads the messages specified by their UIDs from the specific remote folder
- (void)loadMessages:(MCOIndexSet*)messageUIDs remoteFolder:(NSString*)remoteFolder;

// fetches the body of the message specified by its UID
- (BOOL)fetchMessageBody:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId urgent:(BOOL)urgent;

@end
