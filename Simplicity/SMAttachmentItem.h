//
//  SMAttachmentItem.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMMessage;

@interface SMAttachmentItem : NSObject

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSData *fileData;

- (id)initWithMessage:(SMMessage*)message attachmentIndex:(NSUInteger)attachmentIndex;

@end
