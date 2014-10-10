//
//  SMMessageComparators.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 8/15/14.
//  Copyright (c) 2014 Evgeny Baskakov. All rights reserved.
//

#import "SMMessage.h"
#import "SMMessageThread.h"
#import "SMMessageComparators.h"

@implementation SMMessageComparators

- (id)init {
	self = [super init];
	if(self) {
		_messagesComparator = ^NSComparisonResult(id a, id b) {
			uint32_t uid1 = [(SMMessage*)a uid];
			uint32_t uid2 = [(SMMessage*)b uid];
			
			return uid1 > uid2? NSOrderedAscending : (uid2 > uid1? NSOrderedDescending : NSOrderedSame);
		};
		
		_messagesComparatorByImapMessage = ^NSComparisonResult(id a, id b) {
			uint32_t uid1 = 0, uid2 = 0;
			
			if([a isKindOfClass:[MCOIMAPMessage class]]) {
				uid1 = [(MCOIMAPMessage*)a uid];
				uid2 = [(SMMessage*)b uid];
			} else {
				uid1 = [(SMMessage*)a uid];
				uid2 = [(MCOIMAPMessage*)b uid];
			}
			
			return uid1 > uid2? NSOrderedAscending : (uid2 > uid1? NSOrderedDescending : NSOrderedSame);
		};
		
		_messagesComparatorByUID = ^NSComparisonResult(id a, id b) {
			uint32_t uid1 = 0, uid2 = 0;
			
			if([a isKindOfClass:[NSNumber class]]) {
				uid1 = [(NSNumber*)a unsignedIntValue];
				uid2 = [(SMMessage*)b uid];
			} else {
				uid1 = [(SMMessage*)a uid];
				uid2 = [(NSNumber*)b unsignedIntValue];
			}
			
			return uid1 > uid2? NSOrderedAscending : (uid2 > uid1? NSOrderedDescending : NSOrderedSame);
		};
		
		_messagesComparatorByDate = ^NSComparisonResult(id a, id b) {
			NSDate *date1 = [(SMMessage*)a date];
			NSDate *date2 = [(SMMessage*)b date];
			
			return [date2 compare:date1];
		};
		
		_messageThreadsComparatorByDate = ^NSComparisonResult(id a, id b) {
			SMMessage *message1 = [a messagesSortedByDate].firstObject;
			SMMessage *message2 = [b messagesSortedByDate].firstObject;
			
			NSDate *date1 = [message1 date];
			NSDate *date2 = [message2 date];
			
			return [date2 compare:date1];
		};
	}

	return self;
}

@end
