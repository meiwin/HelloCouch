//
//  DemoAppDelegate.h
//  Hello Couch
//
//  Created by Meiwin Fu on 21/9/13.
//  Copyright (c) 2013 Demo. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDatabaseUpdatedNotification @"kDatabaseUpdatedNotification"

@interface DemoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic, readonly) CouchServer * localCouchServer;

- (CouchDatabase *)localCouchDatabase:(NSError **)error;

@end
