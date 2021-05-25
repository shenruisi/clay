//
//  AppDelegate.m
//  HowToUse
//
//  Created by ris on 3/9/16.
//  Copyright © 2016 ris. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <Clay/ClayTakeoff.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    [ClayTakeoff startWithResourcePath:[[NSBundle mainBundle] resourcePath]
//                          entranceFile:@"ViewController.txt"];
//
//    NSDictionary *d = @{};
//    id a  = [d performSelector:@selector(objectForKeySafety:)
//                    withObject:@"aaa"];
    
    
    
    [ClayTakeoff startWithResourcePath:[[NSBundle mainBundle] resourcePath]
    entranceFile:@"main.js"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    ViewController *v = [[ViewController alloc] init];
    v.clayDelegate = self;
    self.window.rootViewController = v;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)beginExcuteScript{
    NSLog(@"beginExcuteScript");
}

- (void)processExpr:(id)expr inFile:(id)file{
    NSLog(@"%@-%@",expr,file);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
