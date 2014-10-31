//
//  SMMessage.h
//  Simplicity
//
//  Created by Evgeny Baskakov on 9/3/13.
//  Copyright (c) 2013 Evgeny Baskakov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MailCore/MailCore.h>

@interface SMMessage : NSObject <MCOHTMLRendererDelegate>

@property (readonly) MCOMessageHeader *header;

@property (readonly) NSString *from;
@property (readonly) NSString *subject;
@property (readonly) NSDate *date;
@property (readonly) uint32_t uid;
@property (readonly) NSString *htmlBodyRendering;
@property (readonly) NSString *folder;

@property (assign) NSData *data;

@property BOOL updated;

+ (NSString*)parseAddress:(MCOAddress*)address;

- (id)initWithRawValues:(int)uid date:(NSDate*)date from:(const unsigned char*)from subject:(const unsigned char*)subject data:(const void*)data dataLength:(int)dataLength folder:(NSString*)folder;

- (id)initWithMCOIMAPMessage:(MCOIMAPMessage*)m folder:(NSString*)folder;

- (BOOL)hasData;
- (void)fetchInlineAttachments;

- (void)updateImapMessage:(MCOIMAPMessage*)m;

- (MCOIMAPMessage*)getImapMessage;

- (NSString*)localizedDate;

@end
