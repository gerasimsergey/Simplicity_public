//
//  SMSearchResultsListCellView.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 11/14/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMSearchResultsListCellView : NSTableCellView

@property IBOutlet NSButton *removeButton;
@property IBOutlet NSButton *reloadButton;
@property IBOutlet NSButton *stopButton;

@property IBOutlet NSProgressIndicator *progressIndicator;

@property NSNumber *searchResultsListRow;

@end
