/*
     File: MapViewController.m
 Abstract: Controls the map view and manages the reverse geocoder to get the current address.
  Version: 1.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <CoreMotion/CoreMotion.h>
#import "MapViewController.h"
#import "PlacemarkViewController.h"
#import "Konashi.h"

@interface MapViewController ()
{
  CMMotionManager *_motionManager;
  NSTimer *timer;
}

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *getAddressButton;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) MKPlacemark *placemark;
@property (nonatomic, strong) MKUserLocation *sharedUserLocation;
@property BOOL iAmIn;

@end

@implementation MapViewController

CLLocationDegrees home_latitude = 34.824482;
CLLocationDegrees home_longitutde = 135.434993;
double radius = 0.01;

double distance(double x1, double y1, double x2, double y2) {
  double dx = x1 - x2;
  double dy = y1 - y2;
  return sqrt(dx * dx + dy * dy);
}

- (CMMotionManager *)sharedMotionManager {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _motionManager = [[CMMotionManager alloc] init];
  });
  return _motionManager;
}

- (IBAction)findKonashi: (id)sender {
  NSLog(@"Finding Konashi.");
  [Konashi find];
  NSLog(@"Ready.");
}

- (void)ready {
  [Konashi pinMode: LED2 mode: OUTPUT];
  [Konashi digitalWrite: LED2 value: HIGH];
  
  [Konashi pinMode: LED3 mode: OUTPUT];
  [Konashi pinMode: LED4 mode: OUTPUT];
  [Konashi pinMode: LED5 mode: OUTPUT];
}

- (void)disconnected {
  // do nothing
}

- (void)updatePioInput {
  // do nothing
}

- (void)letMeBeInIfXIsHigh: (double)x {
  // NSLog(@"x = %f", x);
  if (x > 0.0) {
    self.iAmIn = YES;
  }
  else {
    self.iAmIn = NO;
  }
}

- (void)checkIAmInOrOut {
  MKUserLocation *userLocation = self.sharedUserLocation;
  
  CLLocationDegrees latitude = userLocation.coordinate.latitude;
  CLLocationDegrees longitude = userLocation.coordinate.longitude;
  NSLog(@"My location is %f, %f", latitude, longitude);
  double d = distance(latitude, longitude, home_latitude, home_longitutde);
  NSLog(@"Distance from my home is %f", d);

#if 0
  // USE THIS CODE FOR LOCATION-AWARE SWITCHING
  if (d < radius) {
    self.iAmIn = YES;
  }
  else {
    self.iAmIn = NO;
  }
#else
  // USE THIS CODE FOR DEMONSTRATION
  CMMotionManager *motionManager = [self sharedMotionManager];
  MapViewController * __weak weakSelf = self;
  if ([motionManager isAccelerometerAvailable] == YES) {
    [motionManager setAccelerometerUpdateInterval: 0.1];
    [motionManager startAccelerometerUpdatesToQueue: [NSOperationQueue mainQueue]
                                        withHandler: ^(CMAccelerometerData *accelerometerData, NSError *error) {
                                          [weakSelf letMeBeInIfXIsHigh: accelerometerData.acceleration.x];
                                          // [weakSelf.graphView addX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];
                                          // [weakSelf setLabelValueX:accelerometerData.acceleration.x y:accelerometerData.acceleration.y z:accelerometerData.acceleration.z];
                                        }];
  }
#endif
  
  if (self.iAmIn == YES) {
    // Raise up Konashi
    NSLog(@"I'm in.");
    [Konashi digitalWrite: LED3 value: HIGH];
    [Konashi digitalWrite: LED4 value: HIGH];
    [Konashi digitalWrite: LED5 value: HIGH];
  }
  else {
    NSLog(@"I'm out.");
    [Konashi digitalWrite: LED3 value: LOW];
    [Konashi digitalWrite: LED4 value: LOW];
    [Konashi digitalWrite: LED5 value: LOW];
  }
}

- (void)timerFire: (id)userInfo {
  [self checkIAmInOrOut];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.iAmIn = NO;
  
  [Konashi initialize];
//  [Konashi addObserver: self
//              selector: @selector(disconnected)
//                  name: KONASHI_EVENT_DISCONNECTED];
  [Konashi addObserver: self
              selector: @selector(ready)
                  name: KONASHI_EVENT_READY];
//  [Konashi addObserver: self
//              selector: @selector(updatePioInput)
//                  name: KONASHI_EVENT_UPDATE_PIO_INPUT];

  timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
                                           target: self
                                         selector: @selector(timerFire:)
                                         userInfo: nil
                                          repeats: YES];

	// Create a geocoder and save it for later.
  self.geocoder = [[CLGeocoder alloc] init];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushToDetail"])
    {
		// Get the destination view controller and set the placemark data that it should display.
        PlacemarkViewController *viewController = segue.destinationViewController;
        viewController.placemark = self.placemark;
    }
}

- (void)mapView: (MKMapView *)mapView didUpdateUserLocation: (MKUserLocation *)userLocation {
  // Center the map the first time we get a real location change.
  static dispatch_once_t centerMapFirstTime;

	if ((userLocation.coordinate.latitude != 0.0) && (userLocation.coordinate.longitude != 0.0)) {
		dispatch_once(&centerMapFirstTime, ^{
			[self.mapView setCenterCoordinate: userLocation.coordinate animated: YES];
		});
    // Check I'm in or out (This code should be replaced by Region Monitoring)
    self.sharedUserLocation = userLocation;
    [self checkIAmInOrOut];
	}
	
	// Lookup the information for the current location of the user.
  [self.geocoder reverseGeocodeLocation: self.mapView.userLocation.location
                      completionHandler: ^(NSArray *placemarks, NSError *error) {
                        if ((placemarks != nil) && (placemarks.count > 0)) {
                          // If the placemark is not nil then we have at least one placemark. Typically there will only be one.
                          _placemark = [placemarks objectAtIndex: 0];
                          // we have received our current location, so enable the "Get Current Address" button
                          [self.getAddressButton setEnabled: YES];
                          }
                        else {
                          // Handle the nil case if necessary.
                        }
                      }];
}

@end
