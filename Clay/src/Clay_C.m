//
//  Clay_C.m
//  Clay
//
//  Created by ris on 4/23/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_C.h"
#import "Clay_Help.h"
#import "Clay_Define.h"


@implementation Clay_C_NSLog

- (id)callC:(NSMutableArray *)args{
    NSString *formatString = ((Grammar *)args[0]).data;
    [args removeObjectAtIndex:0];
    
    NSMutableArray *newArgs = [NSMutableArray array];
    
    for (int i = 0; i < args.count; ++i) {
        Grammar *argA = args[i];
        [newArgs addObject:argA.data];
    }

    
    NSLog(formatString,clay_va_arg(newArgs,0),
          clay_va_arg(newArgs,1),
          clay_va_arg(newArgs,2),
          clay_va_arg(newArgs,3),
          clay_va_arg(newArgs,4),
          clay_va_arg(newArgs,5),
          clay_va_arg(newArgs,6),
          clay_va_arg(newArgs,7),
          clay_va_arg(newArgs,8),
          clay_va_arg(newArgs,9),
          clay_va_arg(newArgs,10));
    
    return nil;
}

@end

@implementation Clay_C_UIGraphicsGetCurrentContext

- (CGContextRef)callC {
    return UIGraphicsGetCurrentContext();
}

@end

@implementation Clay_C_UIGraphicsBeginImageContext

- (id)callC:(NSDictionary *)sizeDic {
    CGSize size;
    size.width = [sizeDic[@"width"] doubleValue];
    size.height = [sizeDic[@"height"] doubleValue];
    UIGraphicsBeginImageContext(size);
    return nil;
}

@end

@implementation Clay_C_UIGraphicsBeginImageContextWithOptions

- (id)callC:(NSDictionary *)sizeDic opaque:(BOOL)opaque scale:(CGFloat)scale {
    CGSize size;
    size.width = [sizeDic[@"width"] doubleValue];
    size.height = [sizeDic[@"height"] doubleValue];
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    return nil;
}

@end

@implementation Clay_C_UIGraphicsGetImageFromCurrentImageContext

- (id)callC {
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
}

@end

@implementation Clay_C_UIGraphicsEndImageContext

- (id)callC {
    UIGraphicsEndImageContext();
    return nil;
}

@end


