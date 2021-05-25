//
//  Clay_C.h
//  Clay
//
//  Created by ris on 4/23/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define Clay_C @"Clay_C_"
@interface Clay_C_NSLog : NSObject

- (id)callC:(NSMutableArray *)args;

@end

@interface Clay_C_UIGraphicsEndImageContext : NSObject

- (id)callC;

@end

@interface Clay_C_UIGraphicsGetCurrentContext : NSObject

- (CGContextRef)callC;

@end

@interface Clay_C_UIGraphicsBeginImageContext : NSObject

- (id)callC:(NSDictionary *)sizeDic;

@end

@interface Clay_C_UIGraphicsGetImageFromCurrentImageContext : NSObject

- (id)callC;

@end


@interface Clay_C_UIGraphicsBeginImageContextWithOptions : NSObject

- (id)callC:(NSDictionary *)sizeDic opaque:(BOOL)opaque scale:(CGFloat)scale;

@end




