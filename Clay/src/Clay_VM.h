//
//  Clay_VM.h
//  Clay
//
//  Created by ris on 5/23/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLIMPContext;
@interface Clay_VM : NSObject

- (instancetype)init;

- (void)evaluateOC:(NSString *)ocCode;

+ (CLIMPContext *)getIMPContext:(NSInvocation *)invocation;
@end
