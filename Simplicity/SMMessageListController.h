//
//  SMMessageListUpdater.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/12/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMSimplicityContainer;
@class SMMessage;

@interface SMMessageListController : NSObject

- (id)initWithModel:(SMSimplicityContainer*)model;
- (void)changeFolder:(NSString*)folder;
- (NSString*)currentFolder;
- (void)fetchMessageBodyUrgently:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId;
- (void)loadSearchResults:(MCOIndexSet*)searchResults folderToSearch:(NSString*)folderToSearch;

@end
