//
//  Beacon.m
//  Beacon
//
//  Created by Daniel Mauer on 13.09.2016.
//
//

#import "Beacon.h"

#import <Cordova/CDV.h>
#import <Cordova/CDVViewController.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <EstimoteSDK/EstimoteSDK.h>


@interface Beacon () <ESTBeaconManagerDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate>


@property (nonatomic, strong) CLBeacon *beacon;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;

@property (nonatomic, strong) NSObject *beaconLocationData;
@property (nonatomic, strong) NSObject *beaconArray;

@property (nonatomic, strong) CLRegion *region;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) CBCentralManager *cbManager;
@property (nonatomic, strong) CBCentralManager *bluetoothManager;

// Test the property
@property(nonatomic, assign, readonly) CBManagerState state;

//: End


@property (nonatomic, assign) bool bluetoothEnabled;

@end

#pragma mark - Implementation

@implementation Beacon
@synthesize delegate;

static Beacon *sharedInstance = nil;

+ (void) initialize
{
    if (self == [Beacon class])
    {
        sharedInstance = [[self alloc] init];
    }
}

+ (Beacon *) sharedManager
{
    return sharedInstance;
}
/*
 *The old format of this exec call has been removed (deprecated since 2.1). Change to: cordova.exec(null, null, 'Service', 'action', [ arg1, arg2 ]);
 *
 *
 - (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
 {
 self = (Beacon*)[super initWithWebView:(UIWebView*)theWebView];
 if (self)
 {
 
 }
 return self;
 }
 */


- (id) init {
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
        self.beaconLocationData = nil;
        
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        
        if([self.beaconManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.beaconManager requestAlwaysAuthorization];
        }
        
        self.beaconArray = [[NSObject alloc] init];
        
        
        // Test
        self.bluetoothManager = [[CBCentralManager alloc]
                                 initWithDelegate:self
                                 queue:dispatch_get_main_queue()
                                 options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
    }
    return self;
}

- (void)start
{
    for (CLBeaconRegion *beacon in [self.locationManager monitoredRegions])
    {
        if ([beacon isKindOfClass:[CLBeaconRegion class]]) {
            CLBeaconRegion *region = beacon;
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            region.notifyEntryStateOnDisplay = YES;
            
            [self.beaconManager startMonitoringForRegion:region];
            [self startRanging];
            [self.beaconManager startRangingBeaconsInRegion: region];
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void) startRanging
{
    for (CLBeaconRegion *beacon in [self.locationManager monitoredRegions])
    {
        if ([beacon isKindOfClass:[CLBeaconRegion class]]) {
            CLBeaconRegion *region = beacon;
            region.notifyOnEntry = YES;
            region.notifyOnExit = YES;
            region.notifyEntryStateOnDisplay = YES;
            
            [self.beaconManager startRangingBeaconsInRegion: region];
        }
        
    }
}



#pragma mark - iBeacon functions

-(void)setHost:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* beaconHost = [command.arguments objectAtIndex:0];
    
    // Save the host into ne nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:beaconHost forKey:@"BeaconHost"];
    [preferences synchronize]; //at the end of storage
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", beaconHost]];
    if (callbackId) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
    
    
    NSUserDefaults *getBeaconPreferences = [NSUserDefaults standardUserDefaults];
    NSString *getBeaconHost = [getBeaconPreferences objectForKey:@"BeaconHost"];
}

- (void)getHost:(CDVInvokedUrlCommand*)command
{
    NSUserDefaults *getBeaconPreferences = [NSUserDefaults standardUserDefaults];
    NSString *getBeaconHost = [getBeaconPreferences objectForKey:@"BeaconHost"];
    
    NSString* callbackId = command.callbackId;
    CDVPluginResult* result = nil;
    if (getBeaconHost != nil) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:getBeaconHost];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}


-(void)setToken:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* token = [command.arguments objectAtIndex:0];
    
    // Save the host into ne nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:token forKey:@"BeaconUsertoken"];
    [preferences synchronize]; //at the end of storage
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", token]];
    if (callbackId) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
}


#pragma mark - check if bluetooth is activated

- (void)checkBluetoothAccess {
    if(!self.cbManager) {
        self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    CBCentralManagerState state = [self.cbManager state];
    if(state == CBCentralManagerStateUnknown) {
        NSLog(@"Bluetooth Status: Unknown");
    }
    else if(state == CBCentralManagerStateUnauthorized) {
        NSLog(@"Bluetooth Status: Denied");
    }
    else {
        NSLog(@"Bluetooth Status: Granted");
    }
}

- (void)startBluetoothStatusMonitoring {
    self.bluetoothManager = [[CBCentralManager alloc]
                             initWithDelegate:self
                             queue:dispatch_get_main_queue()
                             options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if ([central state] == CBCentralManagerStatePoweredOn) {
        self.bluetoothEnabled = YES;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setObject:@"YES" forKey:@"BluetoothStatus"];
        [preferences synchronize]; //at the end of storage
    }
    else {
        self.bluetoothEnabled = NO;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setObject:@"NO" forKey:@"BluetoothStatus"];
        [preferences synchronize]; //at the end of storage
    }
    
    /* available options
     CBCentralManagerStateUnknown
     CBCentralManagerStateResetting
     CBCentralManagerStateUnsupported
     CBCentralManagerStateUnauthorized
     CBCentralManagerStatePoweredOff
     CBCentralManagerStatePoweredOn
     
     */
    
    // This delegate method will monitor for any changes in bluetooth state and respond accordingly
    
    NSString *stateString = nil;
    switch(_bluetoothManager.state)
    {
        case CBCentralManagerStateResetting: stateString = @"The connection with the system service was momentarily lost, update imminent."; break;
        case CBCentralManagerStateUnsupported: stateString = @"The platform doesn't support Bluetooth Low Energy."; break;
        case CBCentralManagerStateUnauthorized: stateString = @"The app is not authorized to use Bluetooth Low Energy."; break;
        case CBCentralManagerStatePoweredOff: stateString = @"Bluetooth is currently powered off."; break;
        case CBCentralManagerStatePoweredOn: stateString = @"Bluetooth is currently powered on and available to use."; break;
        default: stateString = @"State unknown, update imminent."; break;
    }
}

- (BOOL) isBluetoothActive
{
    // Load the storage data from nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *bluetoothStatus = [preferences stringForKey:@"BluetoothStatus"];
    
    if ([bluetoothStatus isEqual: @"YES"]) {
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - iBeacon Functions new

-(void)addBeacon:(CDVInvokedUrlCommand *)command
{
    if (self.isBluetoothActive) {
        // setup the beacon manager
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        
        NSString* callbackId = command.callbackId;
        
        NSMutableDictionary *options = [command.arguments objectAtIndex:0];
        
        NSString *beaconId = [[options objectForKey:KEY_BEACON_ID] stringValue];
        NSString *proximityUUID = [options objectForKey:KEY_BEACON_PUUID];
        NSInteger majorInt = [[options objectForKey:KEY_BEACON_MAJOR] intValue];
        NSInteger minorInt = [[options objectForKey:KEY_BEACON_MINOR] intValue];
        NSUUID *puuid = [[NSUUID alloc] initWithUUIDString:proximityUUID];
        
        // setup the beacon region
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:puuid
                                                                    major:majorInt
                                                                    minor:minorInt
                                                               identifier:beaconId];
 
        // let us know when we exit and enter a region
        self.beaconRegion.notifyOnEntry = YES;
        self.beaconRegion.notifyOnExit = YES;
        
        
        // must have on iOS8
        [self.beaconManager requestAlwaysAuthorization];
        
        // start monitoring
        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
        [self returnMonitoringForBeaconRegionCallback:callbackId];
        
        // start ranging
        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
        
        // must have on iOS8
        //[self.beaconManager requestAlwaysAuthorization];
        
    } else {
        /*
         if(!self.cbManager) {
         self.cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
         }
         */
    }
}

- (void)removeBeacon:(CDVInvokedUrlCommand*)command {
    
    if (self.isBluetoothActive) {
        NSString* callbackId = command.callbackId;
        
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        [options setObject:[command.arguments objectAtIndex:0] forKey:@"bid"];
        
        // load all regions
        NSSet *beaconRegions = [self.beaconManager monitoredRegions];
        
        // create array with only beacons
        NSMutableArray* beaconRegionArray = [[NSMutableArray alloc] init];
        for (id region in beaconRegions.allObjects) {
            if ([region isKindOfClass:[CLCircularRegion class]]) {
                // it's for geofencing regions
            } else if ([region isKindOfClass:[CLBeaconRegion class]]) {
                // filtered out beacons from watched regions
                [beaconRegionArray addObject:region];
            }
        }
        
        
        NSString * combinedStuff = [command.arguments componentsJoinedByString:@"separator"];
        for (CLBeaconRegion *beaconRegion in beaconRegionArray) {
            
            if ([combinedStuff isEqualToString:beaconRegion.identifier]) {
                
                NSString *beaconIdentifier = (NSString *)beaconRegion.identifier;
                NSString *beaconProximityUUID = (NSString *)beaconRegion.proximityUUID.UUIDString;
                
                int beaconMajorInt = [beaconRegion.major intValue];
                int beaconMinorInt = [beaconRegion.minor intValue];
                
                NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:beaconProximityUUID];
                
                CLBeaconRegion *beaconRegionStop = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                                                           major:beaconMajorInt
                                                                                           minor:beaconMinorInt
                                                                                      identifier:beaconIdentifier];
                
                // stop monitoring
                [self.beaconManager stopMonitoringForRegion:beaconRegionStop];
                [self returnMonitoringForBeaconRegionCallback:callbackId];
            }
        }
        
    }
    
}




#pragma mark - iBeacon ranging and interaction


// check for region failure
-(void)beaconManager:(ESTBeaconManager *)manager monitoringDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    
    NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [posError setObject: [NSNumber numberWithInt: error.code] forKey:@"code"];
    [posError setObject: region.identifier forKey: @"beacocnid"];
    
}

// check permission status
-(void)beaconManager:(ESTBeaconManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus: %d", status);
}

//Beacon manager did enter region
- (void)beaconManager:(ESTBeaconManager *)manager didEnterRegion:(CLBeaconRegion *)region
{

    [self triggerURL:@"far" withIdentifier:region.identifier];
    [[self locationManager] startRangingBeaconsInRegion:region];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self triggerURL:@"far" withIdentifier:region.identifier];
    });
    
}

//Beacon Manager did exit the region
- (void)beaconManager:(ESTBeaconManager *)manager didExitRegion:(CLBeaconRegion *)region
{
    // call the url
    [self triggerURL:@"away" withIdentifier:region.identifier];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self triggerURL:@"away" withIdentifier:region.identifier];
    });
    
}



-(void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    if (beacons.count > 0) {
        CLBeacon *firstBeacon = [beacons firstObject];
        [self textForProximity:firstBeacon.proximity withIdentifier:region.identifier];
    }
}

-(NSString *)textForProximity:(CLProximity)proximity withIdentifier:(NSString *)identifier
{
    
    switch (proximity) {
        case CLProximityFar:
            NSLog(@"far");
            [self triggerURL:@"far" withIdentifier:identifier];
            return @"Far";
            break;
        case CLProximityNear:
            NSLog(@"near");
            [self triggerURL:@"near" withIdentifier:identifier];
            return @"Near";
            break;
        case CLProximityImmediate:
            NSLog(@"immediate");
            [self triggerURL:@"immediate" withIdentifier:identifier];
            return @"Immediate";
            break;
        case CLProximityUnknown:
            NSLog(@"unknown " );
            [self triggerURL:@"unknown" withIdentifier:identifier];
            return @"Unknown";
            break;
        default:
            break;
    }
}


-(void)getMessage
{
    UILocalNotification *msg = [[UILocalNotification alloc]init];
    msg.alertBody = @"Youve done it!";
    msg.soundName = @"Default.mp3";
    NSLog(@"Youve entered");
    [[UIApplication sharedApplication] presentLocalNotificationNow:msg];
}


- (void)getWatchedBeaconIds:(CDVInvokedUrlCommand*)command {
    
    if (self.isBluetoothActive) {
        NSString* callbackId = command.callbackId;
        
        // init the beacon manager
        self.beaconManager = [[ESTBeaconManager alloc] init];
        self.beaconManager.delegate = self;
        
        
        // init all monitored regions
        NSSet *beaconRegions = [self.beaconManager monitoredRegions];
        
        
        // create array with only beacons
        NSMutableArray* beaconRegionArray = [[NSMutableArray alloc] init];
        for (id region in beaconRegions.allObjects) {
            if ([region isKindOfClass:[CLCircularRegion class]]) {
                
                // it's for geofencing regions
                
            } else if ([region isKindOfClass:[CLBeaconRegion class]]) {
                
                // filtered out beacons from watched regions
                [beaconRegionArray addObject:region];
            }
        }
        
        // loop the array and put the identifier into a new array
        NSMutableArray *watchedBeaconRegions = [NSMutableArray array];
        for (CLBeaconRegion *beaconRegion in beaconRegionArray) {
            [watchedBeaconRegions addObject:beaconRegion.identifier];
        }
        
        
        NSMutableDictionary* regionStatus = [NSMutableDictionary dictionaryWithCapacity:3];
        CDVPluginResult* result = nil;
        
        if (callbackId != nil) {
            [regionStatus setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
            [regionStatus setObject: @"BeaconRegion Success" forKey: @"message"];
            [regionStatus setObject: watchedBeaconRegions forKey: @"beaconRegionids"];
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:watchedBeaconRegions];
        } else {
            [regionStatus setObject: [NSNumber numberWithInt: CDVCommandStatus_ERROR] forKey:@"code"];
            [regionStatus setObject: @"BeaconRegion Error" forKey: @"message"];
            [regionStatus setObject: watchedBeaconRegions forKey: @"beaconRegionids"];
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:regionStatus];
        }
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
        
    }
    
}




#pragma mark - iBeacon common

- (void) returnMonitoringForBeaconRegionCallback:(NSString *)callbackId {
    NSMutableDictionary* posStatus = [NSMutableDictionary dictionaryWithCapacity:2];
    
    CDVPluginResult* result = nil;
    if (callbackId != nil) {
        [posStatus setObject: [NSNumber numberWithInt: CDVCommandStatus_OK] forKey:@"code"];
        [posStatus setObject: @"BeaconRegion Success" forKey: @"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:posStatus];
    } else {
        [posStatus setObject: [NSNumber numberWithInt: CDVCommandStatus_ERROR] forKey:@"code"];
        [posStatus setObject: @"BeaconRegion Error" forKey: @"message"];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posStatus];
    }
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void) triggerURL:(NSString *)proximity withIdentifier:(NSString *)identifier {
    
    // Load the storage data from nsuserdefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *getHost = [preferences stringForKey:@"BeaconHost"];
    NSString *getUsertoken = [preferences stringForKey:@"BeaconUsertoken"];
    
    
    //    NSString* beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/away?s=&token=%@", getHost, region.identifier, getUsertoken];
    //    NSString *beaconUrl = [NSString stringWithFormat:@"https://www.myfavorito.com/sf/daniel_beacons/%@/%@/?device(id)=9876543210&s=", identifier, proximity];
    //    NSString *beaconUrl = [NSString stringWithFormat:@"https://%@/sf/daniel_beacons/%@/%@/?token=%@&s=", getHost, identifier, proximity, getUsertoken];
    //    NSString *beaconUrl = [NSString stringWithFormat:@"https://%@/sf/daniel_beacons/%@/%@/?device(id)=0&s=", getHost, identifier, proximity ];
    
#pragma mark - Change for golive
    // Live URL
    NSString *beaconUrl = [NSString stringWithFormat:@"https://%@/sf/beacons/%@/%@/?token=%@&s=", getHost, identifier, proximity, getUsertoken];
    
    
    NSURL* sfUrl = [NSURL URLWithString:beaconUrl];
    
    // set the request
    NSURLRequest* sfRequest = [NSURLRequest requestWithURL:sfUrl];
    NSOperationQueue* sfQueue = [[NSOperationQueue alloc] init];
    __block NSUInteger tries = 0;
    
    typedef void (^CompletionBlock)(NSURLResponse *, NSData *, NSError *);
    __block CompletionBlock completionHandler = nil;
    
    // Block to start the request
    dispatch_block_t enqueueBlock = ^{
        [NSURLConnection sendAsynchronousRequest:sfRequest queue:sfQueue completionHandler:completionHandler];
    };
    
    completionHandler = ^(NSURLResponse *sfResponse, NSData *sfData, NSError *sfError) {
        tries++;
        if (sfError) {
            if (tries < 3) {
                enqueueBlock();
                NSLog(@"Error: %@", sfError);
            } else {
                NSLog(@"Cancel");
            }
        } else {
            NSString* myResponse;
            myResponse = [[NSString alloc] initWithData:sfData encoding:NSUTF8StringEncoding];
        }
    };
    
    
    // Load NSUserDefaults
    NSDate *savedDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"beaconTimer%@_%@", identifier, proximity]];
    
    // if savedDate = nil set current time + 5 minutes
    if (savedDate == nil) {
        NSLog(@"No entry found");
        NSDate *dateNow = [NSDate date];
        NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
        NSLog(@"dateNow: %@", dateNow);
        NSLog(@"dateToSave: %@", dateToSave);
        // Save the timer into ne nsuserdefaults
        NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
        [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", identifier, proximity]];
        [setBeaconTimers synchronize]; //at the end of storage
    }
    
    // compare current date and saved date
    NSDate *dateNow = [NSDate date];
    switch ([dateNow compare:savedDate]){
        case NSOrderedAscending:
//            NSLog(@"NSOrderedAscending");
//            NSLog(@"Time is into the future");
            
            break;
        case NSOrderedSame:
//            NSLog(@"NSOrderedSame");
            break;
        case NSOrderedDescending:
//            NSLog(@"NSOrderedDescending");
//            NSLog(@"Date is in past");
            
            NSDate *dateNow = [NSDate date];
            NSDate *dateToSave = [dateNow dateByAddingTimeInterval:300];
            // Save the timer into ne nsuserdefaults
            NSUserDefaults *setBeaconTimers = [NSUserDefaults standardUserDefaults];
            [setBeaconTimers setObject:dateToSave forKey:[NSString stringWithFormat:@"beaconTimer%@_%@", identifier, proximity]];
            [setBeaconTimers synchronize]; //at the end of storage
            
            enqueueBlock();
            
            break;
    }
}



@end
