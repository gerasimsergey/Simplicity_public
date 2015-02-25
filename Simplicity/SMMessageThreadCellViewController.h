//
//  SMMessageThreadCellViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/24/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMMessageBodyViewController;

@interface SMMessageThreadCellViewController : NSViewController

- (id)initCollapsed:(Boolean)collapsed;

- (void)setMessage:(SMMessage*)message;
- (void)updateMessage;

- (Boolean)loadMessageBody;

- (void)enableCollapse:(Boolean)enable;

- (void)collapse;
- (void)uncollapse;

- (void)toggleAttachmentsPanel;

#pragma mark Finding contents

- (NSUInteger)highlightAllOccurrencesOfString:(NSString*)str matchCase:(Boolean)matchCase;
- (void)markOccurrenceOfFoundString:(NSUInteger)index;
- (void)removeMarkedOccurrenceOfFoundString;
- (void)removeAllHighlightedOccurrencesOfString;

@end
