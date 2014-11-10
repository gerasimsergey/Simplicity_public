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

- (id)initWithLocalFolderName:(NSString*)localFolderName;

- (void)startMessagesUpdate;
- (void)cancelUpdate;

- (void)fetchMessageHeaders;
- (void)fetchMessageBodies:(NSString*)remoteFolder;
- (BOOL)fetchMessageBody:(uint32_t)uid remoteFolder:(NSString*)remoteFolder threadId:(uint64_t)threadId urgent:(BOOL)urgent;

@end
