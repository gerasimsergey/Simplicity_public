//
//  SMAppDelegate.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SMSimplicityContainer.h"

@class SMAppController;
@class SMImageRegistry;

@interface SMAppDelegate : NSObject <NSApplicationDelegate>

+ (NSURL*)appDataDir;

@property SMAppController *appController;
@property SMSimplicityContainer *model;
@property SMImageRegistry *imageRegistry;

@property (assign) IBOutlet NSWindow *window;

@end
