//
//  Clay_Exception.m
//  Clay
//
//  Created by ris on 4/26/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Clay_Exception.h"

void __clay_exception_log(NSString *reason){
    NSLog(@"\nclay.exception\n{\n\treason : %@\n}\n",reason);
}