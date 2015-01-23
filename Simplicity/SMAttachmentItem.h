//
//  SMAttachmentItem.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 1/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMAttachmentItem : NSObject

@property NSString *fileName;

- (id)initWithFileName:(NSString*)fileName;

@end
