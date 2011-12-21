//
//  JabberClientAppDelegate.h
//  JabberClient
//
//  Created by cesarerocchi on 8/3/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMBuddyListViewController;

@interface JabberClientAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SMBuddyListViewController *viewController;

@end

