//
//  SMMessageListCellView.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/31/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import "SMMessageListCellView.h"

@implementation SMMessageListCellView {
	Boolean _fieldsInitialized;
}

- (void)initFields {
	if(_fieldsInitialized)
		return;
	
	NSFont *font = [_fromTextField font];
	
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSFontBoldTrait];
	
	[_fromTextField setFont:font];
	
	_fieldsInitialized = true;
}

@end
