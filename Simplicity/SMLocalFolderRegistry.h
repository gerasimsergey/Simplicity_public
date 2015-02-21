//
//  SMLocalFolderRegistry.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/22/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMLocalFolder;

@interface SMLocalFolderRegistry : NSObject

- (SMLocalFolder*)createLocalFolder:(NSString*)localFolderName remoteFolder:(NSString*)remoteFolderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder;
- (SMLocalFolder*)getLocalFolder:(NSString*)folderName;
- (void)removeLocalFolder:(NSString*)folderName;
- (void)keepFoldersMemoryLimit;

@end
