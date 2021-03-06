//
//  SMChatViewController.m
//  jabberClient
//
//  Created by cesarerocchi on 7/16/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import "SMChatViewController.h"
#import "XMPP.h"
#import "NSString+Utils.h"

@implementation SMChatViewController

@synthesize messageField, chatWithUser, tView;
@synthesize keyboardToolbar;
@synthesize chatManager = _chatManager;

#pragma mark - Convenience Methods (unnecessary)

- (XMPPStream *)xmppStream {
	return self.chatManager.xmppStream;
}

#pragma mark - Initialization

- (id)initWithUser:(NSString *) userName chatManager:(id <ChatManager>)chatManager {

  if (self = [super init]) {
    NSLog(@"Starting chat with friend: %@", userName);
    self.chatManager = chatManager;

		self.chatWithUser = userName; // @ missing
		turnSockets = [[NSMutableArray alloc] init];
	}
	
	return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {

  [super viewDidLoad];
  self.tView.delegate = self;
  self.tView.dataSource = self;
  [self.tView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

  self.messageField.delegate = self;

  messages = [[NSMutableArray alloc ] init];

	self.chatManager.messageDelegate = self;
  [self.messageField becomeFirstResponder];

  //NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
  NSString *userID = @"dk@localhost";
  //XMPPJID *jid = [XMPPJID jidWithString:@"cesare@YOURSERVER"];
  XMPPJID *jid = [XMPPJID jidWithString: userID];

  NSLog(@"Attempting TURN connection to %@", jid);

  TURNSocket *turnSocket = [[TURNSocket alloc] initWithStream:[self xmppStream] toJID:jid];

  [turnSockets addObject:turnSocket];

  [turnSocket startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  [turnSocket release];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - IBActions

- (IBAction)hideKeyboard:(id)sender {
	//[self.textView resignFirstResponder];
	[self.messageField resignFirstResponder];
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect frame = self.keyboardToolbar.frame;
	frame.origin.y = self.view.frame.size.height - 260.0;
	self.keyboardToolbar.frame = frame;
	
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect frame = self.keyboardToolbar.frame;
	//frame.origin.y = self.view.frame.size.height;
  frame.origin.y = self.view.frame.size.height - frame.size.height;

	self.keyboardToolbar.frame = frame;
	
	[UIView commitAnimations];
}

#pragma mark - TURNSocket Methods

- (void)turnSocket:(TURNSocket *)sender didSucceed:(GCDAsyncSocket *)socket {
	
	NSLog(@"TURN Connection succeeded!");
	NSLog(@"You now have a socket that you can use to send/receive data to/from the other person.");
		
	[turnSockets removeObject:sender];
}

- (void)turnSocketDidFail:(TURNSocket *)sender {
	
	NSLog(@"TURN Connection failed!");
	[turnSockets removeObject:sender];
	
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == self.messageField) {
    [self sendMessage];
    return YES;
  }
  return YES;
}

#pragma mark - Actions

- (IBAction) closeChat {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)sendMessage {
    NSString *messageStr = self.messageField.text;
	
    if([messageStr length] > 0) {

      NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
      [body setStringValue:messageStr];

      NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
      [message addAttributeWithName:@"type" stringValue:@"chat"];
      [message addAttributeWithName:@"to" stringValue:self.chatWithUser];
      [message addChild:body];

      NSLog(@"Sending message: %@ to user: %@", messageStr, self.chatWithUser);

      [self.xmppStream sendElement:message];

      self.messageField.text = @"";

      NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
      [m setObject:[messageStr substituteEmoticons] forKey:@"msg"];
      [m setObject:@"you" forKey:@"sender"];
      [m setObject:[NSString getCurrentTime] forKey:@"time"];

      [messages addObject:m];
      [self.tView reloadData];
      [m release];

    }
	
	NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 
												   inSection:0];
	
	[self.tView scrollToRowAtIndexPath:topIndexPath 
					  atScrollPosition:UITableViewScrollPositionMiddle 
							  animated:YES];
}

#pragma mark - Table view delegates

static CGFloat padding = 20.0;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary *s = (NSDictionary *) [messages objectAtIndex:indexPath.row];
	
	static NSString *CellIdentifier = @"MessageCellIdentifier";
	
	SMMessageViewTableCell *cell = (SMMessageViewTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[SMMessageViewTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}

	NSString *sender = [s objectForKey:@"sender"];
	NSString *message = [s objectForKey:@"msg"];
	NSString *time = [s objectForKey:@"time"];
	
	CGSize  textSize = { 260.0, 10000.0 };
	CGSize size = [message sizeWithFont:[UIFont boldSystemFontOfSize:13]
					  constrainedToSize:textSize 
						  lineBreakMode:UILineBreakModeWordWrap];
	
	size.width += (padding/2);
	
	cell.messageContentView.text = message;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.userInteractionEnabled = NO;
	
	UIImage *bgImage = nil;
		
	if ([sender isEqualToString:@"you"]) { // left aligned
	
		bgImage = [[UIImage imageNamed:@"orange.png"] stretchableImageWithLeftCapWidth:24  topCapHeight:15];
		
		[cell.messageContentView setFrame:CGRectMake(padding, padding*2, size.width, size.height)];
		
		[cell.bgImageView setFrame:CGRectMake( cell.messageContentView.frame.origin.x - padding/2, 
											  cell.messageContentView.frame.origin.y - padding/2, 
											  size.width+padding, 
											  size.height+padding)];
				
	} else {
	
		bgImage = [[UIImage imageNamed:@"aqua.png"] stretchableImageWithLeftCapWidth:24  topCapHeight:15];
		
		[cell.messageContentView setFrame:CGRectMake(320 - size.width - padding, 
													 padding*2, 
													 size.width, 
													 size.height)];
		
		[cell.bgImageView setFrame:CGRectMake(cell.messageContentView.frame.origin.x - padding/2, 
											  cell.messageContentView.frame.origin.y - padding/2, 
											  size.width+padding, 
											  size.height+padding)];
		
	}
	
	cell.bgImageView.image = bgImage;
	cell.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@ %@", sender, time];
	
	return cell;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary *dict = (NSDictionary *)[messages objectAtIndex:indexPath.row];
	NSString *msg = [dict objectForKey:@"msg"];
	
	CGSize  textSize = { 260.0, 10000.0 };
	CGSize size = [msg sizeWithFont:[UIFont boldSystemFontOfSize:13]
				  constrainedToSize:textSize 
					  lineBreakMode:UILineBreakModeWordWrap];
	
	size.height += padding*2;
	
	CGFloat height = size.height < 65 ? 65 : size.height;
	return height;
	
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [messages count];
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	return 1;
	
}

#pragma mark - Chat delegates

- (void)newMessageReceived:(NSMutableDictionary *)messageContent {
	
	NSString *m = [messageContent objectForKey:@"msg"];
	
	[messageContent setObject:[m substituteEmoticons] forKey:@"msg"];
	[messageContent setObject:[NSString getCurrentTime] forKey:@"time"];
	[messages addObject:messageContent];
	[self.tView reloadData];

	NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 
												   inSection:0];
	
	[self.tView scrollToRowAtIndexPath:topIndexPath 
					  atScrollPosition:UITableViewScrollPositionMiddle 
							  animated:YES];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
  [messageField release];
  [self.chatWithUser release];
  [tView release];

  [super dealloc];
}

@end
