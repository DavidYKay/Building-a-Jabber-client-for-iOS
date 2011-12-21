//
//  jabberClientViewController.m
//  jabberClient
//
//  Created by cesarerocchi on 7/13/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import "SMBuddyListViewController.h"

#import "XMPP.h"
#import "XMPPRoster.h"

@implementation SMBuddyListViewController

@synthesize tView, addBuddyView, buddyField;

@synthesize chatManager = _chatManager;

#pragma mark - Factory / Convenience

- (XMPPStream *)xmppStream {
	return self.chatManager.xmppStream;
}

- (XMPPRoster *)xmppRoster {
	return self.chatManager.xmppRoster;
}

#pragma mark - Initialization

- (id)initWithChatManager:(id <ChatManager>)chatManager
{
  if (self = [super init]) {
    _chatManager = chatManager;
  }
  return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tView.delegate = self;
  self.tView.dataSource = self;

  self.chatManager.chatDelegate = self;
  onlineBuddies = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	NSString *login = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
	
	if (login) {
    if ([self.chatManager connect]) {
			NSLog(@"show buddy list");
		}
	} else {
		[self showLogin];
	}
}

#pragma mark - Table view delegates

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"UserCellIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	NSString *s = (NSString *) [onlineBuddies objectAtIndex:indexPath.row];
	cell.textLabel.text = s;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [onlineBuddies count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *userName = (NSString *) [onlineBuddies objectAtIndex:indexPath.row];
  SMChatViewController *chatController = [[SMChatViewController alloc] initWithUser:userName chatManager: self.chatManager];
	[self presentModalViewController:chatController animated:YES];
}

#pragma mark - Chat delegate

- (void)newBuddyOnline:(NSString *)buddyName {
	if (![onlineBuddies containsObject:buddyName]) {
		[onlineBuddies addObject:buddyName];
		[self.tView reloadData];
	}
}

- (void)buddyWentOffline:(NSString *)buddyName {
	[onlineBuddies removeObject:buddyName];
	[self.tView reloadData];
}

- (void)didDisconnect {
	[onlineBuddies removeAllObjects];
	[self.tView reloadData];
}

#pragma mark - UI Listeners

- (IBAction) addBuddy {
	
	//	XMPPJID *newBuddy = [XMPPJID jidWithString:self.buddyField.text];
	//	[self.xmppRoster addBuddy:newBuddy withNickname:@"ciao"];
	
}

- (IBAction) showLogin {
	
	SMLoginViewController *loginController = [[SMLoginViewController alloc] init];
	[self presentModalViewController:loginController animated:YES];
	
}

- (IBAction) directMessage {

  // open an alert with text input
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Talk With" message:@"Enter a username:"
                                                 delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
  alert.delegate = self;
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  [alert show];
  [alert release];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSLog(@"clickedButtonAtIndex: %d", buttonIndex);
	// use "buttonIndex" to decide your action

  if (buttonIndex == 1) {
    UITextField *textField = [actionSheet textFieldAtIndex: 0];
    NSString *userName = textField.text;

    SMChatViewController *chatController = [[SMChatViewController alloc] initWithUser:userName chatManager: self.chatManager];
    [self presentModalViewController:chatController animated:YES];
  }
}

#pragma mark - Cleanup

- (void)dealloc {
  [tView release];
  [addBuddyView dealloc];
  [buddyField dealloc];

  [super dealloc];
}

@end
