//
//  ChatManager.h
//  JabberClient
//
//  Created by David Kay on 12/21/11.
//  Copyright (c) 2011 Gargoyle Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SMChatDelegate.h"
#import "SMMessageDelegate.h"

@class XMPPStream;
@class XMPPRoster;

@protocol ChatManager <NSObject>

@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPRoster *xmppRoster;

@property (nonatomic, assign) id  <SMChatDelegate> chatDelegate;
@property (nonatomic, assign) id  <SMMessageDelegate> messageDelegate;

- (BOOL)connect;
- (void)disconnect;

@end
