//
//  SMSearchDescriptor.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/15/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMSearchDescriptor : NSObject

@property (readonly) NSString *searchPattern;
@property (readonly) NSString *localFolder;

@property Boolean searchFailed;

- (id)init:(NSString*)searchPattern localFolder:(NSString*)localFolder;

@end
