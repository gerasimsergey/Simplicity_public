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
@property (readonly) NSArray *mainFolders;
@property (readonly) NSArray *favoriteFolders;
@property (readonly) NSArray *folders;

- (void)updateIMAPFolders:(NSArray *)folders;

@end
