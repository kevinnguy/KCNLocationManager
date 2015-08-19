//
//  LocationManager.m
//  Location
//
//  Created by Kevin Nguy on 8/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "KCNLocationManager.h"

@import CoreLocation;
@import UIKit;

@interface KCNLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *locationArray;
@property (nonatomic, copy) CLLocation *lastLocation;
@property (nonatomic, copy) CLLocation *currentLocation;

@property (nonatomic, strong) NSTimer *restartLocationUpdateTimer;

@property (nonatomic, strong) NSMutableArray *backgroundTaskArray;
@property (nonatomic) UIBackgroundTaskIdentifier masterTask;


@end

NSTimeInterval const kDefaultLocationManagerTimerInterval = 60.0f;

@implementation KCNLocationManager

+ (instancetype)sharedManager {
    static KCNLocationManager *sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    
    return sharedManager;
}


#pragma mark - Lifecycle
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.locationManagerTimerInterval = kDefaultLocationManagerTimerInterval;
    self.enableLogging = YES;

    self.locationManager = [CLLocationManager new];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.delegate = self;
    
    self.locationArray = [NSMutableArray new];
    
    self.backgroundTaskArray = [NSMutableArray new];
    self.masterTask = UIBackgroundTaskInvalid;
    

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - Post update to server
- (void)uploadCurrentLocation:(void (^)(CLLocation *))uploadBlock {
    // Find the best location from the array based on accuracy
    CLLocation *bestLocation = self.locationArray.firstObject;
    for (NSInteger i = 1; i < self.locationArray.count; i++){
        CLLocation *location = [self.locationArray objectAtIndex:i];
        if(location.horizontalAccuracy <= bestLocation.horizontalAccuracy){
            bestLocation = location;
        }
    }
    
    if (self.locationArray.count == 0) {
        // Sometimes due to network issue or unknown reason, you could not get the location during that period
        [self log:@"KCNLocationManager: KCNLocationManager: Unable to get location, use the last known location" arguments:nil];
        self.currentLocation = self.lastLocation;
    } else {
        self.currentLocation = bestLocation;
    }
    
    // Post location to server
    if (self.currentLocation) {
        uploadBlock(self.currentLocation);
    }
    
    // Clear unused locations
    [self.locationArray removeAllObjects];
}

#pragma mark - Notifications
- (void)applicationDidEnterBackground {
    [self updateLocation];
    [self beginNewBackgroundTask];
}

#pragma mark - Location 
- (KCNLocationTrackingStatus)locationTrackingStatus {
    if (![CLLocationManager locationServicesEnabled]) {
        return KCNLocationTrackingStatusLocationServicesDenied;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        return KCNLocationTrackingStatusLocationServicesDenied;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return KCNLocationTrackingStatusLocationServicesRestricted;
    }
    
    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied) {
        return KCNLocationTrackingStatusBackgroundRefreshDenied;
    }
    
    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted) {
        return KCNLocationTrackingStatusBackgroundRefreshRestricted;
    }
    
    return KCNLocationTrackingStatusAllowed;
}

- (void)startLocationTracking {
    if ([self locationTrackingStatus] != KCNLocationTrackingStatusAllowed) {
        [self log:@"KCNLocationManager: Can't startLocationTracking. locationTrackingStatus is not allowed" arguments:nil];
        return;
    }
    
    [self log:@"KCNLocationManager: startLocationTracking" arguments:nil];
    
    // Remove UIApplicationDidEnterBackgroundNotification in case it was already added
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self updateLocation];
}

- (void)stopLocationTracking {
    [self log:@"KCNLocationManager: stopLocationTracking" arguments:nil];
    
    if (self.restartLocationUpdateTimer) {
        [self.restartLocationUpdateTimer invalidate];
        self.restartLocationUpdateTimer = nil;
    }
    
    [self.locationManager stopUpdatingLocation];
    [self.locationArray removeAllObjects];
}

- (void)restartLocationUpdates {
    [self log:@"KCNLocationManager: restartLocationUpdates" arguments:nil];
    
    if (self.restartLocationUpdateTimer) {
        [self.restartLocationUpdateTimer invalidate];
        self.restartLocationUpdateTimer = nil;
    }
    
    [self updateLocation];
}

- (void)updateLocation {
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Background tasks
- (UIBackgroundTaskIdentifier)beginNewBackgroundTask {
    UIApplication *application = [UIApplication sharedApplication];
    
    UIBackgroundTaskIdentifier backgroundTask = UIBackgroundTaskInvalid;
    if (![application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
        return UIBackgroundTaskInvalid;
    }
    
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [self log:@"KCNLocationManager: expire background task id:" arguments:@[@(backgroundTask)]];
    }];
    
    if (self.masterTask == UIBackgroundTaskInvalid) {
        self.masterTask = backgroundTask;
        [self log:@"KCNLocationManager: started master task id:" arguments:@[@(backgroundTask)]];
    } else {
        [self log:@"KCNLocationManager: started background task id:" arguments:@[@(backgroundTask)]];
        [self.backgroundTaskArray addObject:@(backgroundTask)];
        [self endBackgroundTasks];
    }
    
    return backgroundTask;
}

- (void)endBackgroundTasks {
    NSInteger count = self.backgroundTaskArray.count;
    for (NSInteger i = 1; i < count; i++) {
        [self log:@"KCNLocationManager: ending background task id:" arguments:@[self.backgroundTaskArray.firstObject]];
        UIBackgroundTaskIdentifier bgTaskId = [self.backgroundTaskArray.firstObject integerValue];
        [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
        [self.backgroundTaskArray removeObjectAtIndex:0];
    }
    
    [self log:@"KCNLocationManager: kept background task id:" arguments:@[self.backgroundTaskArray.firstObject]];
}

#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    [self log:@"KCNLocationManager: locationManager didUpdateLocations" arguments:nil];
    
    for (CLLocation *location in locations) {
        NSTimeInterval locationAge = -[location.timestamp timeIntervalSinceNow];
        if (locationAge > 30.0) {
            continue;
        }
        
        // Select location with good accuracy
        if (location &&
            location.horizontalAccuracy > 0 &&
            location.horizontalAccuracy < 2000 &&
            location.coordinate.latitude != 0.0 &&
            location.coordinate.longitude != 0.0){
            
            self.lastLocation = location;
            [self.locationArray addObject:location];
        }
    }
    
    if (self.restartLocationUpdateTimer) {
        return;
    }
    
    [self beginNewBackgroundTask];
    
    // Restart the location manager 
    self.restartLocationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:self.locationManagerTimerInterval
                                                  target:self
                                                selector:@selector(restartLocationUpdates)
                                                userInfo:nil
                                                 repeats:NO];
}

#pragma mark - Logging
- (void)log:(NSString *)logString arguments:(NSArray *)arguments {
    if (!self.enableLogging) {
        return;
    }
    
    for (NSObject *arg in arguments) {
        logString = [logString stringByAppendingString:[NSString stringWithFormat:@" %@", arg.description]];
    }
    
    NSLog(@"%@", logString);
}


@end





























