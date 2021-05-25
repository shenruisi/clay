//
//  Clay_Help.h
//  Clay
//
//  Created by yin shen on 12/4/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrammarCache;
@interface Grammar : NSObject
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) id data2;
@property (nonatomic, strong) id data3;
@property (nonatomic, copy) NSString *expr;

- (instancetype)initWithWithGrammar:(GrammarCache *)gC;
@end

@interface GrammarCache : NSObject
@property (nonatomic, strong) NSString *code;
@property (nonatomic, assign) NSInteger dataKey;
@property (nonatomic, assign) NSInteger dataKey2;
@property (nonatomic, assign) NSInteger dataKey3;
- (instancetype)initWithWithGrammar:(Grammar *)g;
@end

typedef struct{
    char *name;
    int arg_len;
}js_function_t;

typedef NS_ENUM(NSInteger, MethodInJSStatus) {
    MethodInJSStatusInit = 1,
    MethodInJSStatusCalling  = 2,
    MethodInJSStatusCalled = 3,
};

@interface NSString(Clay_String_Search)
- (NSString *)catC:(char)c;
- (NSString *)lCat:(NSString *)s;
- (NSString *)cat:(NSString *)s;
- (NSInteger)find:(NSString *)aString;
- (NSInteger)findExactly:(NSString *)aString;
- (NSInteger)rFind:(NSString *)aString;
- (NSArray *)split:(NSString *)separator;
- (NSInteger)find:(NSString *)aString inRange:(NSRange)range;
- (NSInteger)rFind:(NSString *)aString inRange:(NSRange)range;
- (NSString *)trim;
@end

@interface NSMutableString(Clay_MutableString)

- (void)cat:(NSString *)s;
- (void)catC:(char)c;
- (void)clean;
- (NSString *)trim;
- (NSMutableString *)mirror;
@end

@interface __stack : NSObject{
    
}

@property (nonatomic, assign) NSInteger flag;

- (BOOL)isEmpty;
- (void)push:(id)obj;
- (id)pop;
- (void)popToIndex:(int)index;
- (id)top;
- (NSInteger)size;
- (id)get:(NSInteger)index;
- (void)print;
- (void)clean;
@end
