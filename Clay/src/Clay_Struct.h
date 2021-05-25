//
//  Clay_Struct.h
//  Demo2
//
//  Created by yin shen on 12/15/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define Clay_Struct @"Clay_Struct_"

@interface Clay_Super : NSObject

@property (nonatomic, assign) id instance;
@property (nonatomic, assign) Class superClass;
@end


@interface Clay_Struct_CGRect : NSObject

- (NSValue *)p0:(CGFloat)p0 p1:(CGFloat)p1 p2:(CGFloat)p2 p3:(CGFloat)p3;
@end


@interface Clay_Struct_CGPoint : NSObject

- (NSValue *)p0:(CGFloat)x p1:(CGFloat)y;
@end

@interface Clay_Struct_CGSize : NSObject

- (NSValue *)p0:(CGFloat)width p1:(CGFloat)height;
@end

@interface Clay_Struct_NSRange : NSObject

- (NSValue *)p0:(CGFloat)loc p1:(CGFloat)len;
@end

@interface Clay_Struct_UIEdgeInsets : NSObject

- (NSValue *)p0:(CGFloat)p0 p1:(CGFloat)p1 p2:(CGFloat)p2 p3:(CGFloat)p3;

@end