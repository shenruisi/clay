//
//  Clay_LL.h
//  Clay
//
//  Created by yin shen on 10/2/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class __stack;
extern void selectorsForName(const char *methodName, SEL possibleSelectors[2]);

@interface Clay_LL : NSObject

- (id)_parsing:(NSURL *)uri;

@property (nonatomic, copy) NSDictionary* (^jsonWrapper)(NSString *);
@property (nonatomic, assign) JSContext* jsContextRef;
@property (nonatomic, strong) __stack *gramStack;
@property (nonatomic, strong) __stack *operatorStack;
@property (nonatomic, strong) __stack *tempGrammaStack;
@property (nonatomic, strong) __stack *gramma4OperatorStack;
@end
