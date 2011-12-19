//
//  JabberClientAppDelegate.h
//  JabberClient
//
//  Created by cesarerocchi on 8/3/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMPPRoster.h"
#import "XMPP.h"
#import "SMChatDelegate.h"
#import "SMMessageDelegate.h"

@class SMBuddyListViewController;

@interface JabberClientAppDelegate : NSObject <UIApplicationDelegate> {
  NSString *password;

  BOOL isOpen;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SMBuddyListViewController *viewController;


@property (nonatomic, readonly) XMPPStream *xmppStream;
@property (nonatomic, readonly) XMPPRoster *xmppRoster;

@property (nonatomic, assign) id  _chatDelegate;  
@property (nonatomic, assign) id  _messageDelegate; 

- (BOOL)connect;
- (void)disconnect;

@end

