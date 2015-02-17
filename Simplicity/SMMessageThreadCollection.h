//
//  SMMessageThreadCollection.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/16/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMMessageThreadCollection : NSObject

@property NSMutableDictionary *messageThreads;
@property NSMutableOrderedSet *messageThreadsByDate;

@end
