//
//  Clay_Help.m
//  Clay
//
//  Created by yin shen on 12/4/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay_Help.h"

#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Define.h>

@interface GrammarCache()
@end

@implementation Grammar

- (instancetype)initWithWithGrammar:(GrammarCache *)gC{
    if (self = [super init]){
        self.code = gC.code;
        if (gC.dataKey) {
            self.data =  [__clay_prefix(R) o:gC.dataKey];
        }
        if (gC.dataKey2) {
            self.data2 = [__clay_prefix(R) o:gC.dataKey2];
        }
        if (gC.dataKey3) {
            self.data3 = [__clay_prefix(R) o:gC.dataKey3];
        }
    }
    
    return self;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"code = %@,data = %@,data2 = %@,data3 = %@,expr = %@",self.code,self.data,self.data2,self.data3,self.expr];
}
@end

@implementation GrammarCache

- (instancetype)initWithWithGrammar:(Grammar *)g{
    if (self = [super init]){
        self.code = g.code;
        if (g.data) {
            if ([g.data isKindOfClass:[NSString class]]) {
                self.dataKey = [__clay_prefix(R) kSO:g.data];
            }
            else{
                self.dataKey = [__clay_prefix(R) kWO:g.data];
            }
        }
        if (g.data2) {
            self.dataKey2 = [__clay_prefix(R) kWO:g.data2];
        }
        if (g.data3) {
            self.dataKey3 = [__clay_prefix(R) kWO:g.data3];
        }
    }
    
    return self;
}

@end

@implementation NSString (Clay_String_Search)

- (NSInteger)find:(NSString *)aString{
    return [self rangeOfString:aString].location;
}

- (NSInteger)findExactly:(NSString *)aString{
    return [self rangeOfString:aString options:NSLiteralSearch].location;
}

- (NSInteger)rFind:(NSString *)aString{
    return [self rangeOfString:aString options:NSBackwardsSearch].location;
}

- (NSArray *)split:(NSString *)separator{
    return [self componentsSeparatedByString:separator];
}

- (NSInteger)find:(NSString *)aString inRange:(NSRange)range{
    return [self rangeOfString:aString
                       options:0
                         range:range].location;
}

- (NSInteger)rFind:(NSString *)aString inRange:(NSRange)range{
    return [self rangeOfString:aString
                       options:NSBackwardsSearch
                         range:range].location;
}

- (NSString *)catC:(char)c{
    return [NSString stringWithFormat:@"%@%c",self,c];
}

- (NSString *)lCat:(NSString *)s{
    return [NSString stringWithFormat:@"%@%@",s,self];
}

- (NSString *)cat:(NSString *)s{
    return [self stringByAppendingFormat:@"%@",s];
}

- (NSString *)trim{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@implementation NSMutableString (Clay_MutableString)

- (void)cat:(NSString *)s{
    [self appendString:s];
}

- (void)catC:(char)c{
    [self appendFormat:@"%c",c];
}

- (void)clean{
    [self setString:@""];
}

- (NSString *)trim{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSMutableString *)mirror{
    return [self mutableCopy];
}

@end

@interface __stack(){
    NSMutableArray *_s;
}
@end

@implementation __stack

- (NSMutableArray *)s{
    if (!_s) _s = [[NSMutableArray alloc] initWithCapacity:10];return _s;
}

- (BOOL)isEmpty{
    return ![self s].count;
}

- (NSInteger)size{
    return [self s].count;
}

- (void)push:(id)obj{
    [[self s] addObject:obj];
}

- (id)pop{
    id top = [[self s] lastObject];
    [[self s] removeLastObject];
    return top;
}

- (void)popToIndex:(int)index{
    int i = 0;
    do{
        [self pop];
        i++;
    }while (i<=index);
}

- (id)top{
    return [[self s] lastObject];
}

- (id)get:(NSInteger)index{
    return [[self s] objectAtIndex:[self s].count-1-index];
}

- (void)clean{
    [[self s] removeAllObjects];
}

- (void)print{
    NSMutableString *printStr = [[NSMutableString alloc] init];
    for (NSInteger i = [self s].count-1; i >= 0; --i) {
        [printStr appendFormat:@"\n|--- %@",[self s][i]];
    }
    NSLog(@"%@",printStr);
}

@end


