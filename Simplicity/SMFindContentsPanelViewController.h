//
//  SMSearchContentsPanelViewController.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 2/22/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMFindContentsPanelViewController : NSViewController

@property IBOutlet NSSearchField *searchField;
@property IBOutlet NSButton *matchCaseCheckbox;
@property IBOutlet NSButton *doneButton;

- (IBAction)findContentsSearchAction:(id)sender;
- (IBAction)findNextAction:(id)sender;
- (IBAction)findPrevAction:(id)sender;

@end
