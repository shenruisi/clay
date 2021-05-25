//
//  ViewController.h
//  HowToUse
//
//  Created by ris on 3/9/16.
//  Copyright © 2016 ris. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITabBarControllerDelegate,
UITableViewDataSource
>

@property (nonatomic, assign) id<NSObject> clayDelegate;
@end

