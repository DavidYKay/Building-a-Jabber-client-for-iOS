//
//  jabberClientViewController.h
//  jabberClient
//
//  Created by cesarerocchi on 7/13/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JabberClientAppDelegate.h"
#import "SMLoginViewController.h"
#import "SMChatViewController.h"
#import "SMChatDelegate.h"
#import "ChatManager.h"

@interface SMBuddyListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SMChatDelegate> {

  UITableView *tView;
  NSMutableArray *onlineBuddies;

  UIView		*addBuddyView;	
  UITextField *buddyField;

}

@property (nonatomic,retain) IBOutlet UITableView *tView;
@property (nonatomic,retain) IBOutlet UIView *addBuddyView;
@property (nonatomic,retain) IBOutlet UITextField *buddyField;

@property (nonatomic, assign) id <ChatManager> chatManager;

- (IBAction) addBuddy;
- (IBAction) showLogin;
- (IBAction) directMessage;

- (id)initWithChatManager:(id <ChatManager>)chatManager;


@end
