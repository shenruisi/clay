//
//  Clay_VMExecutor.h
//  Demo2
//
//  Created by yin shen on 11/18/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

extern const NSString *JS_METHOD_MAP;
extern const NSString *JS_VARIABLE_MAP;

@interface Clay_VMExecutor : NSObject

+ (instancetype)shared;
- (void)run:(NSString *)script;
@property (nonatomic, strong) JSContext *_jsContext;
@property (nonatomic, strong) NSString *scriptLoadPath;
@end
