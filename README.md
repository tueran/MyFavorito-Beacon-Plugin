---
title: Beacon
description: Beacon Plugin.
---
<!--
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->


# MyFavorito-Beacon-Plugin

This plugin let set your `Beacons`.




## Installation

    cordova plugin add https://github.com/tueran/MyFavorito-Beacon-Plugin

- Add to AppDelegate.m
```bash
#import <EstimoteSDK/EstimoteSDK.h>
#import "Beacon.h"

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    ......

    [[Beacon sharedManager] start];
}

```

- Add to ViewController.h
```bash
#import <EstimoteSDK/EstimoteSDK.h>

@interface MainViewController : CDVViewController <ESTBeaconManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLBeacon *beacon;
@property (nonatomic, strong) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;

@end
```

- Add to ViewController.m
```bash
#import "Beacon.h"

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[Beacon sharedManager] setDelegate:self];   
}
```

    

## Properties

- addBeacon - Add a region to moitoring
- removeBeacon - Remove a region from monitoring
- setHost - sets the Host form the call url from outside
- setToken - sets the user toker from outside
- getWatchedBeaconIds - Returns a list of currently monitored region identifiers.


## Beacon.addBeacon

To add a new region to be monitored use the Beacon Beacon.addRegion function. The parameters are:

### Supported Platforms

- iOS

### Quick Example

```js
// bid - String - This is a unique identifier.
// puuid - String - proximity UUID
// major - int - latitude of the region.
// minor - int - Specifies the radius in meters of the region.

Beacon.addBeacon(function(){
                             alert('success');
                             }, function(){
                             alert('error');
                             }, {
                             bid: 1234567890,
                             puuid: 'f7826da6-4fa2-4e98-8024-bc5b71e0893e',
                             major: 11111,
                             minor: 23456
                             });

```


## Beacon.removeBeacon

To remove an existing region use the Beacon removeRegion function. The parameters are:

### Supported Platforms

- iOS

### Quick Example

```js
// bid - String - This is a unique identifier.
// puuid - String - proximity UUID
// major - int - latitude of the region.
// minor - int - Specifies the radius in meters of the region.

Beacon.removeBeacon(function(){
                             alert('success');
                             }, function(){
                             alert('error');
                             }, 
                             1234567890
                             );

```


## Beacon.getWatchedBeaconIds

To retrieve the list of identifiers of currently monitored regions use the Beacon getWatchedRegionIds function. No parameters. The result object contains an array of strings in regionids.

### Supported Platforms

- iOS

### Quick Example

```js
Beacon.getWatchedBeaconIds(
                             function(result) {
                             alert("success: " + result);
                             },
                             function(error) {
                             alert("error");
                             });

```


## Beacon.setHost

To set the host for the callback url use Beacon setHost. It works only with https://

### Supported Platforms

- iOS

### Quick Example

```js
Beacon.setHost(function(success){}, function(error){}, 'myfavorito.com');


```


## Beacon.setToken

To set the token for the callback url use Beacon setToken. It works only with https://

### Supported Platforms

- iOS

### Quick Example

```js
Beacon.setToken(function(success){}, function(error){}, 'hkja8z8klahkjh899842kljah');


```