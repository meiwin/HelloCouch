//
//  DemoAppDelegate.m
//  Hello Couch
//
//  Created by Meiwin Fu on 21/9/13.
//  Copyright (c) 2013 Demo. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "MainViewController.h"

@interface DemoAppDelegate ()
{
    CouchServer * _localCouchServer;
    CouchDatabase * _localCouchDatabase;
    
    NSInteger _pullTotal;
    NSInteger _pullCompleted;
}
- (void)setupSyncingForDatabase:(CouchDatabase *)db withDatabaseNamed:(NSString *)dbName atRemoteServerURL:(NSString *)remoteURL;
@end

@implementation DemoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MainViewController * mainvc = [[MainViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController * navvc = [[UINavigationController alloc] initWithRootViewController:mainvc];
    self.window.rootViewController = navvc;
    
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Couch Database 
- (CouchServer *)localCouchServer
{
    if (_localCouchServer == nil)
    {
        _localCouchServer = [CouchTouchDBServer sharedInstance];
    }
    return _localCouchServer;
}
- (CouchDatabase *)localCouchDatabase:(NSError **)error
{
    if (_localCouchDatabase == nil)
    {
        _localCouchDatabase = [self.localCouchServer databaseNamed:@"hellocouch"];
        if (![_localCouchDatabase ensureCreated:error])
        {
            NSLog(@"Failed to create local database: %@", *error);
        }
        else
        {
            NSLog(@"> Database Created");
            _localCouchDatabase.tracksChanges = YES;
            [self setupSyncingForDatabase:_localCouchDatabase
                        withDatabaseNamed:@"hellocouch" atRemoteServerURL:@"https://meiwin:password@meiwin.cloudant.com"];
        }
    }
    return _localCouchDatabase;
}
- (void)setupSyncingForDatabase:(CouchDatabase *)db withDatabaseNamed:(NSString *)dbName atRemoteServerURL:(NSString *)remoteURL
{
    NSURL *remoteDatabaseURL = [NSURL URLWithString:dbName relativeToURL:[NSURL URLWithString:remoteURL]];

    NSArray *replications = [db replicateWithURL:remoteDatabaseURL exclusively:NO];
    for (CouchPersistentReplication *repl in replications)
    {
        repl.continuous = YES;
        if (repl.pull)
        {
            [repl addObserver:self forKeyPath:@"completed" options:0 context:NULL];
            [repl addObserver:self forKeyPath:@"mode" options:0 context:NULL];
            [repl addObserver:self forKeyPath:@"error" options:0 context:NULL];
        }
    }
    NSLog(@"> Replication Setup");
}
- (void)databaseDidUpdate
{
    if (_pullTotal == _pullCompleted)
    {
        NSLog(@"> Database Updates Available");
        [[NSNotificationCenter defaultCenter] postNotificationName:kDatabaseUpdatedNotification object:nil];
    }
}
// KVO
- (void) observeValueForKeyPath: (NSString*)keyPath ofObject: (id)object
                         change: (NSDictionary*)change context: (void*)context
{
    if ([@"completed" isEqual:keyPath] || [@"total" isEqualToString:keyPath])
    {
        _pullTotal = [object total];
        _pullCompleted = [object completed];
        [self databaseDidUpdate];
    }
}
@end
