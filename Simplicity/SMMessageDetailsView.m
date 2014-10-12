//
//  SMMessageDetailsView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 5/26/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageDetailsViewController.h"
#import "SMMessageDetailsView.h"

@implementation SMMessageDetailsView {
	SMMessageDetailsViewController *__weak _controller;
}

- (void)setViewController:(SMMessageDetailsViewController*)controller {
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
