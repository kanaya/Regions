//
//  PRViewController.m
//  Regions
//
//  Created by Ichi Kanaya on 4/29/14.
//  Copyright (c) 2014 Pinapple. All rights reserved.
//

#import "PRViewController.h"
#import "Konashi.h"

@interface PRViewController ()

@end

@implementation PRViewController

- (IBAction)findKonashi: (id)sender {
  NSLog(@"Finding Konashi.");
  [Konashi find];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  [Konashi initialize];
  [Konashi addObserver: self
              selector: @selector(ready)
                  name: KONASHI_EVENT_READY];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)ready {
  [Konashi pinMode: LED2 mode: OUTPUT];
  [Konashi digitalWrite: LED2 value: HIGH];
}


@end
