//
//  ChatManager.h
//  JabberClient
//
//  Created by David Kay on 12/21/11.
//  Copyright (c) 2011 Gargoyle Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ChatManager.h"


@interface SMChatManager : NSObject <ChatManager> {
}

+ (SMChatManager *)sharedInstance;

@end
