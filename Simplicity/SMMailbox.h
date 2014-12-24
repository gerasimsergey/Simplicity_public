//
//  SMFolderTree.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/22/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMFolder;

@interface SMMailbox : NSObject

@property (readonly) SMFolder *rootFolder;

- (void)updateIMAPFolders:(NSArray *)folders;
- (NSArray*)folders;

@end
