//
//  Clay.m
//  Demo2
//
//  Created by yin shen on 11/18/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay.h"
#import <Clay/Clay_LL.h>
#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Define.h>
#import <Clay/Clay_Help.h>

const static NSString *_CUSTOM_PROTOCOL_SCHEME = @"clay://";
extern void selectorsForName(const char *methodName, SEL possibleSelectors[2]);
extern const NSString *JS_VARIABLE_MAP;

@implementation Clay

- (id)super:(id)obj{
    NSString *param = [NSString stringWithFormat:
                       @"@(%ld)",
                       [__clay_prefix(R) kWO:obj]];
    return [self _bridge:__SUPER__ param:param];
}

- (id)class:(NSString *)classDefine withImpl:(NSDictionary *)impl{
    NSString *param = [NSString stringWithFormat:
                       @"%@_&_@(%ld)",
                       classDefine,
                       [__clay_prefix(R) kWO:impl]];
    return [self _bridge:__CLASS__ param:param];
}

- (id)protocol:(NSString *)protocolDefine withImpl:(NSDictionary *)methodDescription{
    NSString *param = [NSString stringWithFormat:
                       @"%@_&_@(%ld)",
                       protocolDefine,
                       [__clay_prefix(R) kWO:methodDescription]];
    return [self _bridge:__PROTOCOL__ param:param];
}

- (id)expr:(NSString *)expression jsVariableDictionary:(NSDictionary *)jsVariableDictionary{
    if ([expression hasPrefix:@"self.groupModel.delegate"]) {
       
        NSLog(@"expression %@",expression);
    }
    
    NSLog(@"expression %@",expression);
    
    NSString *expr = expression;
    if (jsVariableDictionary.count >0 ){
        expr = __replaceOptionalJSObject(expression,jsVariableDictionary);
    }
    
    NSString *param = [NSString stringWithFormat:@"expr[%@",expr];
    
    id obj = [self _bridge:__EXPR__ param:param];
    
    return obj;
}

- (void)log:(id)expression{
    NSLog(@"\nclay.log:\n{\nvalue: %@\ntype: %@\n}",expression,[expression class]);
}

#pragma -
#pragma Type Convert
- (int)n2i:(NSNumber *)n{ return [n intValue]; }
- (float)n2f:(NSNumber *)n{ return [n floatValue]; }
- (float)n2l:(NSNumber *)n{ return [n longValue]; }
- (NSString *)n2s:(NSNumber *)n{ return [n stringValue]; }

- (id)_bridge:(NSString *)func param:(NSString *)param{
    
    Clay_LL *ll = [[Clay_LL alloc] init];
    
    id ret = [ll _parsing:
              [NSURL URLWithString:
               [[NSString stringWithFormat:@"%@%@?%@",_CUSTOM_PROTOCOL_SCHEME,func,param] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
              ];
    return ret;
     
}


static inline NSString *__replaceOptionalJSObject(NSString *expr,NSDictionary *currentJSVariableDictionary){
    NSString *r = [expr copy];
    NSMutableString *capInstance = [[NSMutableString alloc] init];
    char lastC = '\0';
    int i = 0, maxJump = 5000;
    while (i < r.length || i > maxJump) {
        char c =  [r characterAtIndex:i];

        if (c == '.'|| c == ',' || c == ')' || c == ';' || c == '='
            || c == '+' || c == '-' || c == '*' || c == '/' || c == '%'
            || c == '&' || c == '|'
            || c == '>' || c == '<'){
            
            if (capInstance.length == 0) { i++;
                //lastC = c;
                continue; }
            
            NSString *replaceStr;
            if ( [capInstance isEqualToString:@"nil"] || [capInstance isEqualToString:@"null"] ) {
                replaceStr = Clay_GOR_Nil;
            }
            else if ( [capInstance isEqualToString:@"YES"] || [capInstance isEqualToString:@"true"] ) {
                replaceStr = Clay_GOR_YES;
            }
            else if ( [capInstance isEqualToString:@"NO"] || [capInstance isEqualToString:@"false"] ) {
                replaceStr = Clay_GOR_NO;
            }
            else{
                id obj;
                
                NSInteger index = i - capInstance.length-1; ///look back one character
                if (index > 0 && [r characterAtIndex:index] == '.' ) { i++; [capInstance clean];
                    //lastC = c;
                    continue; }
                
                NSString *trimedCap = [capInstance stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ((obj = currentJSVariableDictionary[trimedCap])) {
                    replaceStr = Clay_GOR_o([__clay_prefix(R) kWO:obj]);
                }

            }
            
            if (replaceStr) {
                r = [r stringByReplacingOccurrencesOfString:capInstance
                                                 withString:replaceStr
                                                    options:0
                                                      range:NSMakeRange(i-capInstance.length, capInstance.length)];
                i+=replaceStr.length-capInstance.length;
            }
            [capInstance clean];
            lastC = c;
        }
        else if (c == '(' || c == ':' || c=='-'){
            [capInstance clean];
        }
        else{
            [capInstance catC:c];
        }
        
        i++;
    }
    
    return r;
}

@end
