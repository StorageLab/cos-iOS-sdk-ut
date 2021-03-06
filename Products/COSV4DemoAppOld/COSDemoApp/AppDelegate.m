//
//  AppDelegate.m
//  COSDemoApp
//
//  Created by 贾立飞 on 16/8/23.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Congfig.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
  
    [Congfig instance].bucket  = @"huadongshanghai";
    [Congfig instance].region = @"sh";
//    [Congfig instance].bucket  = @"liudg1";
   [Congfig instance].dir  =@"dir3";


//    [Congfig instance].bucket  = @"guangzhou";
//    [Congfig instance].region = @"gz";
//     [Congfig instance].dir  =@"dir2";
    
    [Congfig instance].fileName  = @"1234567890myadmin";
   
    
//    [Congfig instance].bucket  =  @"aaaa";
//    [Congfig instance].dir  =@"dir";
//    [Congfig instance].fileName  = @"admin12312345";
//    [Congfig instance].region = @"sh";
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    ViewController *fileController = [[ViewController alloc] init];
    UITabBarItem *tabDirBarItem = [[UITabBarItem alloc]initWithTitle:@"文件" image:[UIImage imageNamed:@"dir_icon.png"] tag:3];
    fileController.tabBarItem = tabDirBarItem;
    tabBarController.viewControllers = @[fileController];
    _nav = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    
    self.window.rootViewController = _nav;
    [self.window makeKeyAndVisible];
    
    return YES;
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
