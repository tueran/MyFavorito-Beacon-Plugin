//
//  Beacon.h
//  Beacon
//
//  Created by Daniel Mauer on 13.09.2016.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MapKit/MapKit.h>
//#import <EstimoteSDK/EstimoteSDK.h>

#define KEY_BEACON_ID @"bid"
#define KEY_BEACON_PUUID @"puuid"
#define KEY_BEACON_MAJOR @"major"
#define KEY_BEACON_MINOR @"minor"

//@interface Beacon : CDVPlugin <ESTBeaconManagerDelegate, CLLocationManagerDelegate>
@interface Beacon : CDVPlugin <CLLocationManagerDelegate>

@property (nonatomic, retain) NSMutableArray* beaconLocationCallbacks;
@property (nonatomic, retain) NSMutableArray* beaconCallbacks;
//@property (nonatomic, weak) id<ESTBeaconManagerDelegate> delegate;


+ (Beacon *) sharedManager;
- (void) start;
- (void) checkBluetoothAccess;
- (BOOL) isBluetoothActive;


#pragma mark Plugin Functions

- (void) addBeacon:(CDVInvokedUrlCommand*)command;
- (void) removeBeacon:(CDVInvokedUrlCommand*)command;
- (void) getWatchedBeaconIds:(CDVInvokedUrlCommand*)command;
- (void) setHost:(CDVInvokedUrlCommand*)command;
- (void) getHost:(CDVInvokedUrlCommand*)command;
- (void) setToken:(CDVInvokedUrlCommand*)command;

@end
