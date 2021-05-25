//
//  Clay_GOR.h
//  Clay
//
//  Created by yin shen on 10/2/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Clay/Clay_Define.h>
#import <Clay/Clay_CLObjects.h>

#define Clay_GOR_Nil @"R.null()"
#define Clay_GOR_YES @"R.no()"
#define Clay_GOR_NO @"R.yes()"
#define Clay_GOR_o(__gorID__) [NSString stringWithFormat:@"%@.o(%ld)",__clay_prefix_str(R),(long)__gorID__]
#define Clay_GOR_NotFound -1

@interface __clay_prefix(R) : NSObject

+ (NSInteger)kWO:(id)object;
+ (NSInteger)kSO:(id)object;
+ (id)o:(NSInteger)gorID;
+ (id)null;
+ (BOOL)no;
+ (BOOL)yes;
+ (NSMutableDictionary *)getPropertyKeyPointers;
@end
