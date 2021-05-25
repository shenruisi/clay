//
//  ViewController.m
//  HowToUse
//
//  Created by ris on 3/9/16.
//  Copyright © 2016 ris. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    @{[[NSArray alloc] initWithObjects:@"1", nil]:[[NSArray alloc] initWithObjects:@"1", nil]};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
