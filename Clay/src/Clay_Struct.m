//
//  Clay_Struct.m
//  Demo2
//
//  Created by yin shen on 12/15/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay_Struct.h"

@implementation Clay_Super
@end

@implementation Clay_Struct_CGRect

- (NSValue *)p0:(CGFloat)p0 p1:(CGFloat)p1 p2:(CGFloat)p2 p3:(CGFloat)p3{
    return [NSValue valueWithCGRect:CGRectMake(p0, p1, p2, p3)];
}

@end


@implementation Clay_Struct_CGPoint

- (NSValue *)p0:(CGFloat)x p1:(CGFloat)y{
    return [NSValue valueWithCGPoint:CGPointMake(x, y)];
}

@end

@implementation Clay_Struct_CGSize

- (NSValue *)p0:(CGFloat)width p1:(CGFloat)height{
    return [NSValue valueWithCGSize:CGSizeMake(width, height)];
}

@end

@implementation Clay_Struct_NSRange

- (NSValue *)p0:(CGFloat)loc p1:(CGFloat)len{
    return [NSValue valueWithRange:NSMakeRange(loc, len)];
}

@end

@implementation Clay_Struct_UIEdgeInsets

- (NSValue *)p0:(CGFloat)p0 p1:(CGFloat)p1 p2:(CGFloat)p2 p3:(CGFloat)p3{
    return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(p0, p1, p2, p3)];
}

@end