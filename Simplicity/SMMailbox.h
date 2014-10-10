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

- (void)updateIMAPFolders:(NSArray *)folders;
- (SMFolder*)root;

@end
