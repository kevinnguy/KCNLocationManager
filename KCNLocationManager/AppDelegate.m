//
//  AppDelegate.m
//  KCNLocationManager
//
//  Created by Kevin Nguy on 8/17/15.
//  Copyright (c) 2015 kevinnguy. All rights reserved.
//

#import "AppDelegate.h"

#import "KCNLocationManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) NSTimer *locationUpdateTimer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UIAlertView *alert;
    
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied){
        alert = [[UIAlertView alloc]initWithTitle:nil
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil];
        [alert show];
    } else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted){
        alert = [[UIAlertView alloc]initWithTitle:nil
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil];
        [alert show];
    } else {
        [KCNLocationManager sharedManager].locationManagerTimerInterval = 5.0f;
        [[KCNLocationManager sharedManager] startLocationTracking];        
        self.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:[KCNLocationManager sharedManager].locationManagerTimerInterval
                                                                    target:self
                                                                  selector:@selector(postLocation)
                                                                  userInfo:nil
                                                                   repeats:YES];
    }
    
    return YES;
}

-(void)postLocation {
    [[KCNLocationManager sharedManager] uploadCurrentLocation:^(CLLocation *location) {
        NSDictionary *json = @{@"lat" : [NSString stringWithFormat:@"%f", location.coordinate.latitude],
                               @"long" : [NSString stringWithFormat:@"%f", location.coordinate.longitude]};
        NSLog(@"json: %@", json.description);
    }];
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
