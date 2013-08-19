//
//  LEViewController.m
//  L10nExample
//
//  Created by Nia Mutiara on 19/8/13.
//  Copyright (c) 2013 example. All rights reserved.
//

#import "LEViewController.h"

@interface LEViewController ()

@end

@implementation LEViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.welcomeLabel.text = @"dfdh";
    self.welcomeLabel.text = NSLocalizedString(@"Welcome", @"Welcome text on the initial view controller");
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
