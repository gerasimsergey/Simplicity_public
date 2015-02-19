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

- (SMLocalFolder*)getLocalFolder:(NSString*)folderName;
- (SMLocalFolder*)getOrCreateLocalFolder:folderName syncWithRemoteFolder:(Boolean)syncWithRemoteFolder;
- (void)removeLocalFolder:(NSString*)folderName;
- (void)keepFoldersMemoryLimit;

@end
