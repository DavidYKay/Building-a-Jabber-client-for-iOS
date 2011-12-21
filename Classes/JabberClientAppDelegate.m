#import "SMBuddyListViewController.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

#import "SMChatManager.h"

@implementation JabberClientAppDelegate

@synthesize window;
@synthesize viewController;

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
  [[SMChatManager sharedInstance] disconnect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  //[self connect];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [self configureLogger];

  self.viewController.chatManager = [SMChatManager sharedInstance];

  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];

  return YES;
}

- (void)dealloc {

  [viewController release];
  [window release];
  [super dealloc];
}

@end
