//
//  Clay.h
//  Demo2
//
//  Created by yin shen on 11/18/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

extern const NSMutableDictionary *methodDefineInJS;

@protocol ClayExport <JSExport>
- (id)super:(id)obj;
- (void)log:(id)expression;
- (int)n2i:(NSNumber *)n;
- (float)n2f:(NSNumber *)n;
- (float)n2l:(NSNumber *)n;
- (NSString *)n2s:(NSNumber *)n;

JSExportAs(class,- (id)class:(NSString *)classDefine withImpl:(NSDictionary *)impl);
JSExportAs(protocol,- (id)protocol:(NSString *)protocolDefine withImpl:(NSDictionary *)methodDescription);
JSExportAs(expr, - (id)expr:(NSString *)expression jsVariableDictionary:(NSDictionary *)jsVariableDictionary);
@end


@interface Clay : NSObject<ClayExport>

@property (nonatomic, assign) JSContext* jsContextRef;
@end
