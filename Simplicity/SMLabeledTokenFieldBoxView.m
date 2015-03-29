//
//  SMLabeledTokenFieldBoxView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 3/28/15.
//  Copyright (c) 2015 Evgeny Baskakov. All rights reserved.
//

#import "SMLabeledTokenFieldBoxViewController.h"
#import "SMLabeledTokenFieldBoxView.h"

@implementation SMLabeledTokenFieldBoxView {
	SMLabeledTokenFieldBoxViewController *__weak _controller;
}

- (void)setViewController:(SMLabeledTokenFieldBoxViewController*)controller {
	_controller = controller;
}

- (NSSize)intrinsicContentSize {
	return [_controller intrinsicContentViewSize];
}

- (void)invalidateIntrinsicContentSize {
	[super invalidateIntrinsicContentSize];
	[_controller invalidateIntrinsicContentViewSize];
}

@end
