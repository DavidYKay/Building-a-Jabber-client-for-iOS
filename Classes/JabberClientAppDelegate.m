#import "SMBuddyListViewController.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

@interface JabberClientAppDelegate()

- (void)setupStream;

- (void)goOnline;
- (void)goOffline;

@end


@implementation JabberClientAppDelegate

@synthesize xmppStream;
@synthesize xmppRoster;
@synthesize window;
@synthesize viewController;
@synthesize _chatDelegate;
@synthesize _messageDelegate;


#pragma mark - Constants

#pragma mark - Logging
- (void)configureLogger {
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  [DDLog addLogger:[DDTTYLogger sharedInstance]];

  DDFileLogger *fileLogger;
  fileLogger = [[DDFileLogger alloc] init];
  fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
  fileLogger.logFileManager.maximumNumberOfLogFiles = 7;

  [DDLog addLogger:fileLogger];
}

#pragma mark - Application Lifecyclce

- (void)applicationWillResignActive:(UIApplication *)application {
	[self disconnect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  //[self connect];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [self configureLogger];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

#pragma mark - XMPP Public Methods

- (void)setupStream {
  NSLog(@"setupStream");
	xmppStream = [[XMPPStream alloc] init];
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)goOnline {
  NSLog(@"goOnline");
	XMPPPresence *presence = [XMPPPresence presence];
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline {
  NSLog(@"goOffline");
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	[[self xmppStream] sendElement:presence];
}

- (BOOL)connect {
  NSLog(@"connect");
	[self setupStream];

	NSString *jabberID   = [[NSUserDefaults standardUserDefaults] stringForKey:@"userID"];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"userPassword"];

	if (![xmppStream isDisconnected]) {
		return YES;
	}

	if (jabberID == nil || myPassword == nil) {
		return NO;
	}

	[xmppStream setMyJID:[XMPPJID jidWithString:jabberID]];
	password = myPassword;

	NSError *error = nil;
	if (![xmppStream connect:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
															message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]]
														   delegate:nil
												  cancelButtonTitle:@"Ok"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];

		return NO;
	}

	return YES;
}

- (void)disconnect {
  NSLog(@"disconnect!");

	[self goOffline];
	[xmppStream disconnect];
	[_chatDelegate didDisconnect];
}

#pragma mark - XMPP delegates

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
  NSLog(@"xmppStream:%@ willSecureWithSettings:%@", sender, settings);
  BOOL allowSelfSignedCertificates = YES;

  if (allowSelfSignedCertificates) {
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}

  BOOL allowSSLHostNameMismatch = YES;
  if (allowSSLHostNameMismatch) {
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	} else {
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).

		NSString *expectedCertName = nil;

		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];

		if ([serverDomain isEqualToString:@"talk.google.com"]) {
			if ([virtualDomain isEqualToString:@"gmail.com"]) {
				expectedCertName = virtualDomain;
			} else {
				expectedCertName = serverDomain;
			}
		} else if (serverDomain == nil) {
			expectedCertName = virtualDomain;
		} else {
			expectedCertName = serverDomain;
		}

		if (expectedCertName) {
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}

}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
  NSLog(@"xmppStreamDidConnect:%@", sender);
	isOpen = YES;
	NSError *error = nil;
	[[self xmppStream] authenticateWithPassword:password error:&error];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
  NSLog(@"xmppStreamDidAuthenticate:%@", sender);
	[self goOnline];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
  NSLog(@"xmppStream:%@ didReceiveIQ: %@", sender, iq);
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
	NSString *msg = [[message elementForName:@"body"] stringValue];
  NSString *from = [[message attributeForName:@"from"] stringValue];

  NSLog(@"didReceiveMessage: %@ fromUser: %@",
      msg,
      from
      );
  if (msg && from) {
    NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
    [m setObject:msg forKey:@"msg"];
    [m setObject:from forKey:@"sender"];

    [_messageDelegate newMessageReceived:m];
    [m release];
  } else {
    NSLog(@"Null message received!");
  }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
  NSLog(@"xmppStream:%@ didReceivePresence: %@", sender, presence);
	NSString *presenceType = [presence type]; // online/offline
	NSString *myUsername = [[sender myJID] user];
  NSString *presenceFromUser = [[presence from] user];
  NSString *hisDomain = presence.from.domain;

	if (![presenceFromUser isEqualToString:myUsername]) {
		if ([presenceType isEqualToString:@"available"]) {
			[_chatDelegate newBuddyOnline:[NSString stringWithFormat:@"%@@%@", presenceFromUser, hisDomain]];
		} else if ([presenceType isEqualToString:@"unavailable"]) {
			[_chatDelegate buddyWentOffline:[NSString stringWithFormat:@"%@@%@", presenceFromUser, hisDomain]];
		}
	}
}

- (void)dealloc {
  [xmppStream removeDelegate:self];
  [xmppRoster removeDelegate:self];

  [xmppStream disconnect];
  [xmppStream release];
  [xmppRoster release];

  [password release];

  [viewController release];
  [window release];
  [super dealloc];
}

@end
