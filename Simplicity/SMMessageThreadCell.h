//
//  SMMessageThreadCell.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/25/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SMMessageThreadCellViewController;
@class SMMessage;

@interface SMMessageThreadCell : NSObject

@property SMMessageThreadCellViewController *viewController;
@property SMMessage *message;

- (id)initWithMessage:(SMMessage*)message viewController:(SMMessageThreadCellViewController*)viewController;

@end
