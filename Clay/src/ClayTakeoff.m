//
//  ClayTakeoff.m
//  Clay
//
//  Created by yin shen on 2/23/16.
//  Copyright (c) 2016 yin shen. All rights reserved.
//

#import "ClayTakeoff.h"
#import "Clay_VMExecutor.h"

#import <Clay/Clay_VM.h>

@implementation ClayTakeoff

static NSString *k_jsResourcePath = nil;
+ (void)startWithResourcePath:(NSString *)resourcePath entranceFile:(NSString *)fileName{
    k_jsResourcePath = resourcePath;
    [Clay_VMExecutor shared].scriptLoadPath = k_jsResourcePath;
    
    NSString *entranceFile = [NSString stringWithContentsOfFile:[k_jsResourcePath
                                                                 stringByAppendingPathComponent:fileName]
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    
    [[Clay_VMExecutor shared] run:entranceFile];
//    Clay_VM *vm = [[Clay_VM alloc] init];
//    [vm evaluateOC:entranceFile];
}

@end
