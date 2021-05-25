//
//  Clay_Kenel.m
//  Clay
//
//  Created by ris on 8/3/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_Kenel.h"
#import <Clay/Clay_LL.h>
#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Help.h>
#import <Clay/Clay_Define.h>

const static NSString *_CUSTOM_PROTOCOL_SCHEME = @"clay://";
@implementation Clay_Kenel

+ (void)expr:(CLExpr *)expr context:(CLContext *)context{
    NSString *clStat = __replaceOptionalVariable(expr.clStat, context);
    NSString *param = [NSString stringWithFormat:@"expr[%@",clStat];
    
    Clay_LL *ll = [[Clay_LL alloc] init];
    
    id ret = [ll _parsing:
              [NSURL URLWithString:
               [[NSString stringWithFormat:@"%@%@?%@",_CUSTOM_PROTOCOL_SCHEME,__EXPR__,param] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
              ];
    
    if (expr.rN.length) {
        context[expr.rN] = ret;
    }

}

static inline NSString *__replaceOptionalVariable(NSString *expr,CLContext *context){
    NSString *r = [expr copy];
    CLStr  *capInstance = [[CLStr alloc] init];
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
            if ( [capInstance isEqualToString:@"nil"] || [capInstance isEqualToString:@"NULL"] ) {
                replaceStr = Clay_GOR_Nil;
            }
            else if ( [capInstance isEqualToString:@"YES"]) {
                replaceStr = Clay_GOR_YES;
            }
            else if ( [capInstance isEqualToString:@"NO"]) {
                replaceStr = Clay_GOR_NO;
            }
            else{
                id obj;
                
                NSInteger index = i - capInstance.length-1; ///look back one character
                if (index > 0 && [r characterAtIndex:index] == '.' ) {
                    i++;
                    [capInstance clean];
                    continue;
                }
                
                NSString *trimedCap = [capInstance stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ((obj = context[trimedCap])) {
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
