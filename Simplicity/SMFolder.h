//
//  SMFolder.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 6/23/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMFolder : NSObject

@property (readonly) NSString *shortName;
@property (readonly) NSString *fullName;
@property (readonly) NSArray *subfolders;

- (id)initWithName:(NSString*)shortName fullName:(NSString*)fullName;
- (SMFolder*)addSubfolder:(NSString*)shortName fullName:(NSString*)fullName;

@end
