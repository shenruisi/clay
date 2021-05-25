//
//  Clay_Runtime.m
//  Clay
//
//  Created by ris on 5/26/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_Runtime.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <Clay/Clay_Define.h>
#import <Clay/Clay_Help.h>

static inline NSString * __isBasicType(NSString *t){
#define __if_basic_type(__t__)\
if ([t isEqualToString:@#__t__]){\
return [NSString stringWithUTF8String:@encode(__t__)];\
}
    
    __if_basic_type(char)
    else __if_basic_type(unichar)
    else __if_basic_type(NSInteger)
    else __if_basic_type(short)
    else __if_basic_type(unsigned short)
    else __if_basic_type(int)
    else __if_basic_type(unsigned int)
    else __if_basic_type(long)
    else __if_basic_type(unsigned long)
    else __if_basic_type(long long)
    else __if_basic_type(unsigned long long)
    else __if_basic_type(CGFloat)
    else __if_basic_type(float)
    else __if_basic_type(double)
    else __if_basic_type(BOOL)
    else __if_basic_type(bool)
    else __if_basic_type(id)
    return nil;
}

BOOL cl_isAutoStepExpr(CLExpr *expr){
    if ([expr.clStat isEqualToString:@"(__seatObj__)++"]){
        return YES;
    }
    return NO;
}

CLExpr *cl_getAutoStepExpr(){
    CLExpr *expr = [[CLExpr alloc] init];
    expr.clStat = @"(__seatObj__)++";
    return expr;
}

typedef enum{
    CLExprSTr_type,
    CLExprSTr_vname,
    CLExprSTr_stat
}CLExprSTr;

static inline BOOL __typeCheck(NSString *candidate){
    if (candidate.length == 0) { return NO; }
    if ((__isBasicType(candidate) || NSClassFromString(candidate))) {
        return YES;
    }
    else{
        @throw [NSException exceptionWithName:@"Clay"
                                       reason:[NSString stringWithFormat:@"wrong type %@",candidate]
                                     userInfo:nil];
    }
}

typedef enum{
    CLStatSTr_undefine,
    CLStatSTr_begin,
    CLStatSTr_ms,
    CLStatSTr_arg,
    CLStatSTr_end
}CLStatSTr;

static inline  BOOL __statTransferMap(NSString *aWord, CLStatSTr *sTr, NSString **replaceWord){
    BOOL ret = NO;
    switch (*sTr) {
        case CLStatSTr_undefine:
        {
            if ([aWord isEqualToString:@"["]) {
                *sTr = CLStatSTr_begin;
                *replaceWord = @"";
                ret = YES;
            }
        }
            break;
        case CLStatSTr_begin:
        {
            if ([aWord isEqualToString:@" "]){
                *sTr = CLStatSTr_ms;
                *replaceWord = @".";
                ret = YES;
            }
        }
            break;
        case CLStatSTr_ms:
        {
            if ([aWord isEqualToString:@":"]) {
                *sTr = CLStatSTr_arg;
                *replaceWord = @"_";
                ret = YES;
            }
            else if ([aWord isEqualToString:@"]"]){
                *sTr = CLStatSTr_end;
                *replaceWord = @")";
                ret = YES;
            }
        }
            break;
        case CLStatSTr_arg:
        {
            if ([aWord isEqualToString:@" "]) {
                *sTr = CLStatSTr_ms;
                ret = YES;
            }
            else if ([aWord isEqualToString:@"]"]){
                *sTr = CLStatSTr_end;
                *replaceWord = @"(";
                ret = YES;
            }
        }
            break;
        default:
            break;
    }
    
    return ret;
}


static inline CLStr *__statConvert(NSString *ocStat,NSInteger *index,CLStatSTr sTr){
    CLStr *clStat = [[CLStr alloc] init];
    CLStr *args = [[CLStr alloc] init];
    for (NSInteger j = *index; j < ocStat.length; ++j){
        NSString*s = [ocStat substringWithRange:NSMakeRange(j, 1)];
        NSString *replaceWord = nil;
        
        if (__statTransferMap(s, &sTr, &replaceWord)) {
            
            if (replaceWord.length > 0) {
                if ([replaceWord isEqualToString:@"("]) {
                    if ([clStat hasSuffix:@"_"]) {
                        clStat = [CLStr stringWithString:[clStat substringToIndex:clStat.length-1]];
                    }
                }
                [clStat cat:replaceWord];
            }
            
            if (CLStatSTr_begin == sTr) {
                j++;
                [clStat cat:__statConvert(ocStat,&j,sTr)];
            }
            else if (CLStatSTr_ms == sTr){
            }
            else if (CLStatSTr_arg == sTr){
                [args cat:@","];
            }
            else if (CLStatSTr_end == sTr){
                
                if ([args hasPrefix:@","]){
                      args = [CLStr stringWithString:[args substringFromIndex:1]];
                }
                [clStat cat:args];
                [clStat cat:@")"];
                [args clean];
                *index = j + 1;
                break;
            }
        }
        else{
            
            switch (sTr) {
                case CLStatSTr_arg:{ [args cat:s]; }
                    break;
                    
                default:{
                    [clStat cat:s];
                }
                    break;
            }
        }
    }
    
    return clStat;
}




CLExpr *cl_getExpr(NSString *ocStat){
    CLStr *cap = [[CLStr alloc] init];
    CLExpr *expr = [[CLExpr alloc] init];
    CLStr *ocStatWithoutTN = [[CLStr alloc] init];
    CLExprSTr sTr = CLExprSTr_type;
    for (int i = 0; i < ocStat.length; ++i) {
        NSString*s = [ocStat substringWithRange:NSMakeRange(i, 1)];
        if ([s isEqualToString:@"*"]){
            if (CLExprSTr_type == sTr) {
                NSString *type = [cap trim];
                if (__typeCheck(type)) {
                    expr.rT = type;
                    sTr = CLExprSTr_vname;
                    [cap clean];
                }
            }
        }
        else if ([s isEqualToString:@" "]){
            if (CLExprSTr_vname == sTr) {
                expr.rN = [cap trim];
                sTr = CLExprSTr_stat;
                [cap clean];
            }
            else if (CLExprSTr_type == sTr){
                NSString *type = [cap trim];
                if (__typeCheck(type)) {
                    expr.rT = type;
                    sTr = CLExprSTr_vname;
                    [cap clean];
                }
            }
            else if (CLExprSTr_stat == sTr){
                 [ocStatWithoutTN cat:s];
            }
        }
        else if ([s isEqualToString:@"="]){
            if (CLExprSTr_vname == sTr) {
                expr.rN = [cap trim];
                sTr = CLExprSTr_stat;
                [cap clean];
            }
        }
        else if ([s isEqualToString:@"["]){
            if (sTr != CLExprSTr_stat) {
                sTr = CLExprSTr_stat;
            }
            [ocStatWithoutTN cat:s];
        }
        else{
            [cap cat:s];
            if (CLExprSTr_stat == sTr) {
                [ocStatWithoutTN cat:s];
            }
        }
    }
    
    expr.ocStat = [ocStatWithoutTN trim];
    
    NSInteger index = 0;
    CLStatSTr ocSTr = CLStatSTr_undefine;
    expr.clStat = __statConvert(expr.ocStat,&index,ocSTr);
        
    return expr;
}



CLIMPContext *cl_getIMPContext(CLIMP *imp,NSInvocation *invocation){
    CLIMPContext *impCxt = [[CLIMPContext alloc] initWithIMP:imp];
    impCxt.context = [CLContext dictionary];
    id sender;
    [invocation getArgument:&sender atIndex:0];
    
    impCxt.context[@"self"] = sender;
    
    NSMethodSignature *signature = [invocation methodSignature];
    
    for (int i = 2,j = 0; i < [signature numberOfArguments]; ++i,++j) {
        __unsafe_unretained id arg;
        [invocation getArgument:&arg atIndex:i];
        
        
    }
    
    return impCxt;
}

