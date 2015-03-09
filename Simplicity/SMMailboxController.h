//
//  SMMailboxController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 7/4/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMMailboxController : NSObject

- (id)initWithModel:(SMSimplicityContainer*)model;
- (void)scheduleFolderListUpdate:(Boolean)now;
- (NSString*)createFolder:(NSString*)folderName parentFolder:(NSString*)parentFolderName;

@end
