//
//  SMChatViewController.h
//  jabberClient
//
//  Created by cesarerocchi on 7/16/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMBuddyListViewController.h"
#import "XMPP.h"
#import "TURNSocket.h"
#import "SMMessageViewTableCell.h"
#import "SMMessageDelegate.h"
#import "ChatManager.h"

@interface SMChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SMMessageDelegate> {
  NSMutableArray *messages;
  NSMutableArray *turnSockets;
}

@property (nonatomic,retain) IBOutlet UITextField *messageField;
@property (nonatomic,retain) NSString *chatWithUser;
@property (nonatomic,retain) IBOutlet UITableView *tView;
@property (nonatomic,retain) IBOutlet UIView *keyboardToolbar;
@property (nonatomic, assign) id <ChatManager> chatManager;

//- (id)initWithUser:(NSString *) userName;
- (id)initWithUser:(NSString *) userName chatManager:(id <ChatManager>)chatManager;
- (IBAction)sendMessage;
- (IBAction)closeChat;

@end
