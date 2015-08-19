//
//  LocationManager.h
//  Location
//
//  Created by Kevin Nguy on 8/17/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation.CLLocation;

@interface KCNLocationManager : NSObject

typedef NS_ENUM(NSInteger, KCNLocationTrackingStatus) {
    KCNLocationTrackingStatusLocationServicesDenied,
    KCNLocationTrackingStatusLocationServicesRestricted,
    KCNLocationTrackingStatusBackgroundRefreshDenied,
    KCNLocationTrackingStatusBackgroundRefreshRestricted,
    KCNLocationTrackingStatusAllowed
};

@property (nonatomic) NSTimeInterval locationManagerTimerInterval;
@property (nonatomic) BOOL enableLogging;

+ (instancetype)sharedManager;

// Check status before starting location tracking
- (KCNLocationTrackingStatus)locationTrackingStatus;

- (void)startLocationTracking;
- (void)stopLocationTracking;

- (void)uploadCurrentLocation:(void (^)(CLLocation *location))uploadBlock;

@end
