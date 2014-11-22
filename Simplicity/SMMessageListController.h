//
//  SMMessageListUpdater.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/12/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMSimplicityContainer;
@class SMLocalFolder;
@class SMMessage;

@interface SMMessageListController : NSObject

- (id)initWithModel:(SMSimplicityContainer*)model;
- (void)changeFolder:(NSString*)folder;
- (void)clearCurrentFolderSelection;
- (SMLocalFolder*)currentLocalFolder;
- (SMLocalFolder*)getLocalFolder:(NSString*)folderName;
- (void)fetchMessageBodyUrgently:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId;
- (void)loadSearchResults:(MCOIndexSet*)searchResults remoteFolderToSearch:(NSString*)remoteFolderToSearch searchResultsLocalFolder:(NSString*)searchResultsLocalFolder;

@end
