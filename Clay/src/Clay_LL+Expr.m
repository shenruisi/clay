//
//  Clay_LL2.m
//  Demo2
//
//  Created by yin shen on 12/2/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//
#import "Clay_LL+Expr.h"

#import <objc/runtime.h>

#import <Clay/Clay_C.h>
#import <Clay/Clay_LL.h>
#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Tree.h>
#import <Clay/Clay_Help.h>
#import <Clay/Clay_Struct.h>
#import <Clay/Clay_Define.h>
#import <Clay/Clay_Object.h>
#import <Clay/Clay_Exception.h>
#import <Clay/Clay_VMExecutor.h>

extern const NSString *JS_METHOD_MAP;

#define __exception(__name__,__reason__,__userInfo__)\
[NSException exceptionWithName:__name__ reason:__reason__ userInfo:__userInfo__];

static int nf_size = 6;
static char *nf[] = {
    "I->C(S)|C()|C.SM(S)|C.SM()|I.IM(S)|I.IM()|I.P|STR|NUM",
    "C->w#r1",
    "A->MS:I)|MS:I,A)|,I)|(I)|,I,A)|(I,A)",
    "S->(A)",
    "SM->w#r3",
    "IM->w#r4",
    "P->w#r5",
    "MS->w#r6",
    "STR->'w'",
    "NUM->w#r7"
};

static NSDictionary *_operators;
static NSDictionary *_unaryOperators;
static NSDictionary *_completeOperators;
static NSDictionary *_compoundOperatorsPrefix;
static NSDictionary *_nfDict;
static NSObject *_seatObj;
static NSString *_lowestOperator = @"";
static NSString *_outsideRightBracket = @"outside_)";
static NSString *_insideRightBracket = @"inside_)";
static NSInteger _codeNotFound = -1;
static NSString *_IFMC = @"instance_from_method_call";

@interface Clay_LL()
@end


@implementation Clay_LL(Expr)

+ (void)initialize{

    
    if (!_operators) {
        _operators = @{
                        @")":@(1),
                        @"++":@(2),@"--":@(2),@"!":@(2),@"~":@(2),
                        @"/":@(3),@"*":@(3),@"%":@(3),
                        @"+":@(4),@"-":@(4),
                        @"<<":@(5),@">>":@(5),
                        @">":@(6),@">=":@(6),@"<":@(6),@"<=":@(6),
                        @"==":@(7),@"!=":@(7),@"<>":@(7),
                        @"&":@(8),
                        @"^":@(9),
                        @"|":@(10),
                        @"&&":@(11),
                        @"||":@(12),
                        @"=":@(14),@"/=":@(14),@"*=":@(14),@"+=":@(14),@"-=":@(14),@"<<=":@(14),@">>=":@(14),@"&=":@(14),@"^=":@(14),@"|=":@(14),
                        @"(":@(15),
                        _outsideRightBracket:@(16),
                        _lowestOperator:@(100)
                       };
    }
    
    if (!_unaryOperators) {
        _unaryOperators = @{
                            @"-":@(YES),@"++":@(YES),@"--":@(YES),@"!":@(YES),@"~":@(YES),
                            };
    }
    
    if (!_completeOperators){
        _completeOperators = @{
                            @"=":@(YES),@"==":@(YES),@"-=":@(YES),@"+=":@(YES),@"/=":@(YES),
                            @"*=":@(YES),@"<=":@(YES),@">=":@(YES),@"<>":@(YES),@"&&":@(YES),@"||":@(YES),
                            };

    }
    
    if (!_compoundOperatorsPrefix){
        //有可能复合运算符的最高优先级
        _compoundOperatorsPrefix = @{
                                     @"=":@(7),     // ==
                                     @"|":@(12),    // ||,|=
                                     @"&":@(11),    // &&, &=
                                     @"!":@(7),     // !=
                                     @"+":@(2),     // ++,+=
                                     @"-":@(2),     // --,-=
                                     @"*":@(14),    // *=
                                     @"/":@(14),    // /=
                                     @">":@(5),     // >>,>=
                                     @"<":@(5)      // <<,<=,<>
                                     };
    }
    
    if (!_nfDict) {
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
        for (int i = 0; i < nf_size; ++i) {
            char * cStr = nf[i];
            NSString *s = [NSString stringWithFormat:@"%s",cStr];
            NSArray *reduceGramSplit = [s split:@"->"];
            NSString *reduceGram = reduceGramSplit[0];
            NSString *reduceExpr = reduceGramSplit[1];
            NSArray *reduceExprSplit = [reduceExpr split:@"|"];
            for (int j = 0; j < [reduceExprSplit count]; ++j) {
                NSString *e = reduceExprSplit[j];
                [mDict setObject:reduceGram forKey:e];
            }
        }
        _nfDict = [mDict copy];
    }
    
    if (!_seatObj){ _seatObj = @"__seat__"; }
}

- (void)printGramStack{
    for (int i = 0; i < [self.gramStack size]; i++) {
        NSLog(@"%@",[self.gramStack get:i]);
    }
    
}

- (id)evaluateStatement:(NSString *)stat{
    return [self produceInstance:[self _lr:stat]];
    @try {
        return [self produceInstance:[self _lr:stat]];
    }
    @catch (NSException *exception) {
        __clay_exception_log([NSString stringWithFormat:@"evaluate statement `%@` failed.",stat]);

    }
    @finally {
        
    }
}

inline static BOOL __isOperator(NSString *aWord,__stack *curGrammarStack){
    if ([aWord isEqualToString:@"("]) {
        if ([curGrammarStack size] > 0
            && (!_operators[((Grammar *)[curGrammarStack get:0]).code] && ![((Grammar *)[curGrammarStack get:0]).code isEqualToString:@","])) {
            return NO;
        }
        else return YES;
    }
    else{
        return _operators[aWord] ? YES : NO;
    }
}

#define __check_cap_words(word) \
[word isEqualToString:@"("]\
|| [word isEqualToString:@"."]\
|| [word isEqualToString:@":"]\
|| [word isEqualToString:@","]

#define __move(stack,grammar) \
if (grammar) { \
[stack push:grammar];\
}
#define __clean(__s__) [__s__ clean]
#define __reduce(__s__,__stat__,__index_ptr__) __reduceStack(__s__,__stat__,__index_ptr__)

#define __EOF(__s__) (__s__.length - 1)
#define __is_unary_operator(__operator__) _unaryOperators[__operator__]

static NSInteger _rb1;
static NSInteger _rb2;
static NSInteger _rb3;
static NSInteger _rb4;
- (id)_lr:(NSString *)stat{
    NSMutableString *cap = [[NSMutableString alloc] init];
    BOOL recordSTR = NO;
    
    for (NSInteger i = 0; i < stat.length; ++i) {
        
        NSString *word = [stat substringWithRange:NSMakeRange(i, 1)];
        
        if (__check_cap_words(word)){
            if (recordSTR) { [cap cat:word]; continue; }
            
            ///skip case float value
            if ([word isEqualToString:@"."]
                && (i-1) > 0
                && [stat characterAtIndex:i-1] >= '0'
                && [stat characterAtIndex:i-1] <= '9'
                && !__isClass(cap)) {
                [cap catC:'.'];
                continue;
            }
            
//            if (cap.length == 0){
//                continue;
//            }

            Grammar *g = __wReduceByRule(self.gramStack,cap,stat,i);
            [cap clean];
            
            if (__grammar_is_C(g)){
                NSMutableArray *gArray;
                CTNode *head = [Clay_Tree head:[Clay_Tree calcKey:g]];
                [Clay_Tree process:head
                          instance:nil
                              stat:stat
                        startIndex:&i
                            gArray:&gArray];

                for (NSInteger j = gArray.count-1;  j >=0 ; --j) { [self.gramStack push:gArray[j]]; }
                continue;
            }
            else{
                if (g != nil){
                    __move(self.gramStack, g);
                }
                
            }
            
            
            if ([word isEqualToString:@","]
                || __grammar_is_P(g)) {
                NSLog(@"> %ld",++_rb1);
                __reduce(self.gramStack, stat, &i);
            }
            
            if (![word isEqualToString:@"("]) {  //解除左括号 对于 __isOperator函数的影响
                Grammar *g2 = [[Grammar alloc] init];
                g2.code = word;
                g2.data = word;
                g2.expr = word;
                __move(self.gramStack, g2);
            }
        }
        else if ([word isEqualToString:@"\""]){
            if (recordSTR) {
                Grammar *g = [[Grammar alloc] init];
                g.code = @"STR";
                g.data = [cap copy];
                g.expr = g.data;
                __move(self.gramStack, g);
            }
            recordSTR = !recordSTR;
        }
        else if ([word isEqualToString:@")"]){
            //__reduce(self.gramStack);
            
            if (cap.length>0) {
                Grammar *g = __wReduceByRule(self.gramStack,cap,stat,i);
                [cap clean];
                __move(self.gramStack,g);
                
                NSLog(@"> %ld",++_rb2);
                __reduce(self.gramStack,stat,&i);
            }
            
            Grammar *gramRBracket = [[Grammar alloc] init];
            gramRBracket.code = word;
            gramRBracket.data = word;
            gramRBracket.expr = word;
            __move(self.gramStack, gramRBracket);
            NSLog(@"> %ld",++_rb3);
            __reduce(self.gramStack,stat,&i);
        }
        else{
            if (!__isOperator(word, self.gramStack)) {
                if (!recordSTR&&[word isEqualToString:@" "]) {
                    continue;
                }
                
                [cap cat:word];
                
                if (i == __EOF(stat)) {
                    Grammar *g = __wReduceByRule(self.gramStack,cap,@")",0); ///如果stat结束部位')',那只可能为属性,补充')'占位
                    [cap clean];
                    __move(self.gramStack, g);
                    NSLog(@"> %ld",++_rb4);
                    __reduce(self.gramStack,stat,&i);
                }
            }
            else{
                if (recordSTR) {
                  [cap cat:word];
                }
            }
        }
        static NSInteger _operatorCount = 0;
        if (!recordSTR && __isOperator(word, self.gramStack) && ![word isEqualToString:@")"]) {
            NSLog(@"> %ld",++_operatorCount);
            Grammar *g = __wReduceByRule(self.gramStack,cap,stat,i);
            __move(self.gramStack, g);
            __reduce(self.gramStack,stat,&i);
            [cap clean];
            
            NSInteger returnIndex;
            Grammar *r = [self __operatorBranch:self.gramStack
                                  checkoutIndex:i
                                           stat:stat
                                    returnIndex:&returnIndex];
            __move(self.gramStack, r);
            i = returnIndex;
        }
        else if ([word isEqualToString:@"("]){
            Grammar *g = [[Grammar alloc] init];
            g.code = @"(";
            g.data = @"(";
            g.expr = @"(";
            __move(self.gramStack, g);
        }
    }
    
#if Clay_DEBUG_MODE
    [self printGramStack];
#endif

    return [self produceGrammar];
}

- (Grammar *)__operatorBranch:(__stack *)grammarStack
                checkoutIndex:(NSInteger)checkoutIndex
                         stat:(NSString *)stat
                  returnIndex:(NSInteger *)returnIndex{
    __reduce(grammarStack,stat,&checkoutIndex);
    
    if (__grammar_is_I(grammarStack.top)) {
        Grammar *top = [grammarStack pop];
        __move(self.gramma4OperatorStack, top);
    }
    
    NSString *op = [stat substringWithRange:NSMakeRange(checkoutIndex, 1)];
    
    Grammar *operatorGrammar = [[Grammar alloc] init];
    operatorGrammar.code = op;
    operatorGrammar.data = op;
    if ([op isEqualToString:@"("]) {
        operatorGrammar.data2 = @(checkoutIndex);
    }
    operatorGrammar.expr = op;
    __move(self.operatorStack, operatorGrammar);
    
    NSMutableString *cap = [[NSMutableString alloc] init];
    BOOL recordSTR = NO;
    BOOL dealWithEnding = NO;
    BOOL checkCompoundOperator = YES;
    for (NSInteger i = checkoutIndex+1;  i < stat.length; ++i) {
        NSString *word = [stat substringWithRange:NSMakeRange(i, 1)];
        if (__isOperator(word,self.tempGrammaStack)) {
            Grammar *top = self.operatorStack.top;
            NSString *topOp = top.data;
            NSString *curOp = word;
            NSInteger curPriority = [_operators[curOp] integerValue];
            if (checkCompoundOperator) {
                
                if ([curOp isEqualToString:@"("]) {
                    Grammar *g = [[Grammar alloc] init];
                    g.code = curOp;
                    g.data = curOp;
                    g.data2 = @(i);
                    g.expr = curOp;
                    __move(self.operatorStack, g);
                    checkCompoundOperator = NO;
                    continue;
                }
                
                NSString *compoundOp = [NSString stringWithFormat:@"%@%@",topOp,curOp];
                
                if (_operators[compoundOp]){
                    top.code = compoundOp;
                    top.data = compoundOp;
                    top.expr = compoundOp;
                }
                else{
                    @throw __exception(@"clay", ([NSString stringWithFormat:@"wrong operator '%@'",compoundOp]), nil);
                }
            }
            else{
                //reduce _tempGrammaStack first
                
                if (cap.length > 0){
                    Grammar *g = __wReduceByRule(self.tempGrammaStack,cap,stat,i);
                    __move(self.tempGrammaStack,g);
                    [cap clean];
                }
                
                __reduce(self.tempGrammaStack,stat,&i);
                
                BOOL isOpRightBracket = NO;
                if ([curOp isEqualToString:@")"]) {
                    checkCompoundOperator = NO;
                    NSInteger leftBPosInOpStack =  __nearestLeftBracketInStack(self.operatorStack);
                    NSInteger leftBPosInTempGrammaStack =  __nearestLeftBracketInStack(self.tempGrammaStack);
                    
                    if (leftBPosInOpStack == _codeNotFound &&  leftBPosInTempGrammaStack == _codeNotFound) {
                        curOp = _outsideRightBracket;
                        isOpRightBracket = NO;
                        goto DEAL_WITH_CURRENT_OPERATOR;
                    }
                    else if (leftBPosInOpStack > leftBPosInTempGrammaStack){
                        isOpRightBracket = YES;
                        Grammar *shoudBeI = __produceGrammar(self.tempGrammaStack);
                        __move(self.gramma4OperatorStack, shoudBeI);
                    }
                    else{
                        curOp = _insideRightBracket;
                        isOpRightBracket = NO;
                        goto DEAL_WITH_CURRENT_OPERATOR;
                    }
                }
                else if ([curOp isEqualToString:@"("]){
                    checkCompoundOperator = NO;
                    
                    if (__isOperator(curOp, self.tempGrammaStack)) {
                        goto DEAL_WITH_CURRENT_OPERATOR;
                    }
                    else{ //可能346行规约后 ( 为方法括号。
                        Grammar *g = [[Grammar alloc] init];
                        g.code = curOp;
                        g.data = curOp;
                        g.data2 = @(i);
                        g.expr = curOp;
                        __move(self.tempGrammaStack, g);
                        continue;
                    }
                    
                }
                else{
                    if ([self.tempGrammaStack size] == 1) {
                        Grammar *shoudBeI = __produceGrammar(self.tempGrammaStack);
                        __move(self.gramma4OperatorStack, shoudBeI);

                    }
                    else{
                        Grammar *top = [self.tempGrammaStack pop];
                        __move(self.gramma4OperatorStack, top);
                    }
                    
                    NSNumber *priority = _compoundOperatorsPrefix[curOp];
                    if (priority) {
                        if (i+1 != __EOF(stat)){
                            NSString *nextWord = [stat substringWithRange:NSMakeRange(i+1, 1)];
                            curPriority = [_operators[[NSString stringWithFormat:@"%@%@",curOp,nextWord]] integerValue];
                        }
                    }
                   
                    checkCompoundOperator = YES;
                }
                
                while (
                       (!isOpRightBracket && curPriority >= [_operators[topOp] integerValue])
                       ||(isOpRightBracket && ![topOp isEqualToString:@"("] )
                       ) {
                        #define __get_value_from_nsnumber(__index__)\
                        double d##__index__ = 0;float f##__index__ = 0;NSInteger i##__index__ = 0;\
                        if (0 == strcmp(n##__index__.objCType,@encode(double))){\
                            d##__index__ = [n##__index__ doubleValue];\
                        }\
                        else if (0 == strcmp(n##__index__.objCType,@encode(float))){\
                            f##__index__ = [n##__index__ floatValue];\
                        }\
                        else if (0 == strcmp(n##__index__.objCType,@encode(NSInteger))){\
                            i##__index__ = [n##__index__ integerValue];\
                        }
                    
                    if (__is_unary_operator(topOp)) {
                        Grammar *maybeI = [self.gramma4OperatorStack top];
                        if (__grammar_is_I(maybeI)) {
                            Grammar *I = [self.gramma4OperatorStack pop];
                            __unaryOperation(self.gramma4OperatorStack, I.data, topOp);
                        }
                    }
                    else{
                        
                        if ([self.gramma4OperatorStack size]<2) {
                            break;
                        }
                        
                        Grammar *I2 = [self.gramma4OperatorStack pop];
                        Grammar *I1 = [self.gramma4OperatorStack pop];
                        __binocularOperation(self.gramma4OperatorStack, I1,I2,topOp);
                    }
                    
                    [self.operatorStack pop];
                    
                    if ([self.operatorStack isEmpty]) { break; }
                    
                    Grammar *top  = [self.operatorStack top];
                    topOp = [top.data copy];
                }
                
                DEAL_WITH_CURRENT_OPERATOR:{
                    
                    if (isOpRightBracket) { //如果右括号 都已经运算完不需要再次入栈并弹出左括号
                        [self.operatorStack pop];
                        checkCompoundOperator = NO;
                        continue;
                    }
                    else{
                        
                        if ([curOp isEqualToString:_outsideRightBracket]) {
                            *returnIndex = i-1;
                            break;
                        }
                        else if ([curOp isEqualToString:_insideRightBracket]){
                            if (cap.length>0) {
                                Grammar *g = __wReduceByRule(self.tempGrammaStack,cap,stat,i);
                                [cap clean];
                                __move(self.tempGrammaStack,g);
                                __reduce(self.tempGrammaStack,stat,&i);
                            }
                            
                            if (self.tempGrammaStack.size > 1){
                                Grammar *top  = [self.operatorStack top];
                                NSString *topOp = [top.data copy];
                                
                                if (!_completeOperators[topOp]) {
                                    top = [self.tempGrammaStack pop];
                                    __move(self.gramma4OperatorStack, top);
                                    
                                    while (![self.operatorStack isEmpty]) {
                                        
                                        top  = [self.operatorStack top];
                                        topOp = [top.data copy];
                                        
                                        if (_completeOperators[topOp]) {
                                            break;
                                        }
                                        
                                        top  = [self.operatorStack pop];
                                        topOp = [top.data copy];
                                        
                                        if (__is_unary_operator(topOp)) {
                                            Grammar *I = [self.gramma4OperatorStack pop];
                                            __unaryOperation(self.gramma4OperatorStack, I.data, topOp);
                                            
                                            if ([topOp isEqualToString:@"-"]) {  //change - to +
                                                Grammar *add = [[Grammar alloc] init];
                                                add.code = @"+";
                                                add.data = @"+";
                                                add.expr = @"+";
                                                __move(self.operatorStack, add);
                                            }
                                        }
                                        else{
                                            Grammar *I2 = [self.gramma4OperatorStack pop];
                                            Grammar *I1 = [self.gramma4OperatorStack pop];
                                            __binocularOperation(self.tempGrammaStack, I1,I2,topOp);
                                        }
                                    }
                                }

                            }
                            
                            Grammar *gramRBracket = [[Grammar alloc] init];
                            gramRBracket.code = @")";
                            gramRBracket.data = @")";
                            gramRBracket.expr = @")";
                            __move(self.tempGrammaStack, gramRBracket);
                            __reduce(self.tempGrammaStack,stat,&i);
                            checkCompoundOperator = NO;
                            
                            if (i == __EOF(stat)) {
                                dealWithEnding = YES;
                            }
                            
                            continue;
                        }
                        else{
                            
                            Grammar *g = [[Grammar alloc] init];
                            g.code = curOp;
                            g.data = curOp;
                            if ([curOp isEqualToString:@"("]) {
                                g.data2 = @(i);
                            }
                            g.expr = curOp;
                            __move(self.operatorStack, g);
                        }
                    }
                    
                    if ([self.tempGrammaStack size]==1) {
                        Grammar *r = __produceGrammar(self.tempGrammaStack);
                        if (r) {
                            __move(self.gramma4OperatorStack, r);
                        }
                    }
                    
                }
            }
            
        }
        else{ //not operator
            checkCompoundOperator = NO;
            if (__check_cap_words(word)) {
                if (recordSTR) { [cap cat:word]; continue; }
                
                
                ///skip case float value
                if ([word isEqualToString:@"."]
                    && (i-1) > 0
                    && [stat characterAtIndex:i-1] >= '0'
                    && [stat characterAtIndex:i-1] <= '9'
                    && !__isClass(cap)) {
                    [cap catC:'.'];
                    continue;
                }
                
                Grammar *g1 = __wReduceByRule(self.tempGrammaStack,cap,stat,i);
                [cap clean];
                
                if (__grammar_is_C(g1)){
                    NSMutableArray *gArray;
                    CTNode *head = [Clay_Tree head:[Clay_Tree calcKey:g1]];
                    [Clay_Tree process:head
                              instance:nil
                                  stat:stat
                            startIndex:&i
                                gArray:&gArray];
                    
                    for (NSInteger j = gArray.count-1;  j >=0 ; --j) { [self.tempGrammaStack push:gArray[j]]; }
                    
                    if (i == __EOF(stat)) {
                        dealWithEnding = YES;
                    }
                    
                    continue;
                }
                else{
                    __move(self.tempGrammaStack, g1);
                }
                
                if ([word isEqualToString:@","]) {
                    __reduce(self.tempGrammaStack,stat,&i);
                    
                    if (self.tempGrammaStack.size == 1) {
                        Grammar *r = __produceGrammar(self.tempGrammaStack);
                        __move(self.gramma4OperatorStack, r);
                        
                        while (![self.operatorStack isEmpty]) {
                            Grammar *top  = [self.operatorStack pop];
                            NSString *topOp = [top.data copy];
                            
                            if (__is_unary_operator(topOp)) {
                                Grammar *I = [self.gramma4OperatorStack pop];
                                __unaryOperation(self.gramma4OperatorStack, I.data, topOp);
                                
                                if ([topOp isEqualToString:@"-"]) {  //change - to +
                                    Grammar *add = [[Grammar alloc] init];
                                    add.code = @"+";
                                    add.data = @"+";
                                    add.expr = @"+";
                                    __move(self.operatorStack, add);
                                }
                            }
                            else{
                                Grammar *I2 = [self.gramma4OperatorStack pop];
                                Grammar *I1 = [self.gramma4OperatorStack pop];
                                __binocularOperation(self.gramma4OperatorStack, I1,I2,topOp);
                            }
                        }
                        
                        *returnIndex = i-1;
                        break;
                    }
                    else if (self.tempGrammaStack.size > 1){
                        Grammar *top  = [self.operatorStack top];
                        NSString *topOp = [top.data copy];
                        
                        if (!_completeOperators[topOp]) {
                            top = [self.tempGrammaStack pop];
                            __move(self.gramma4OperatorStack, top);
                            
                            while (![self.operatorStack isEmpty]) {
                                
                                top  = [self.operatorStack top];
                                topOp = [top.data copy];
                                
                                if (_completeOperators[topOp]) {
                                    break;
                                }
                                
                                top  = [self.operatorStack pop];
                                topOp = [top.data copy];
                                
                                if (__is_unary_operator(topOp)) {
                                    Grammar *I = [self.gramma4OperatorStack pop];
                                    __unaryOperation(self.gramma4OperatorStack, I.data, topOp);
                                    
                                    if ([topOp isEqualToString:@"-"]) {  //change - to +
                                        Grammar *add = [[Grammar alloc] init];
                                        add.code = @"+";
                                        add.data = @"+";
                                        add.expr = @"+";
                                        __move(self.operatorStack, add);
                                    }
                                }
                                else{
                                    Grammar *I2 = [self.gramma4OperatorStack pop];
                                    Grammar *I1 = [self.gramma4OperatorStack pop];
                                    __binocularOperation(self.tempGrammaStack, I1,I2,topOp);
                                }
                            }
                        }
                       
                    }
                }
                else if (__grammar_is_P(g1)){
                    __reduce(self.tempGrammaStack,stat,&i);
                }
                
                Grammar *g2 = [[Grammar alloc] init];
                g2.code = word;
                g2.data = word;
                if ([word isEqualToString:@"("]) {
                    g2.data2 = @(i);
                }
                g2.expr = word;
                __move(self.tempGrammaStack, g2);
                
            }
            else if ([word isEqualToString:@"\""]){
                if (recordSTR) {
                    Grammar *g = [[Grammar alloc] init];
                    g.code = @"STR";
                    g.data = [cap copy];
                    g.expr = g.data;
                    __move(self.tempGrammaStack, g);
                }
                recordSTR = !recordSTR;
                
                if (i == __EOF(stat)) {
                    dealWithEnding = YES;
                    break;
                }
            }
            else if ([word isEqualToString:@")"]){
                __reduce(self.tempGrammaStack,stat,&i);
                
                if (cap.length>0) {
                    Grammar *g = __wReduceByRule(self.tempGrammaStack,cap,stat,i);
                    [cap clean];
                    __move(self.tempGrammaStack,g);
                    __reduce(self.tempGrammaStack,stat,&i);
                }
                
                Grammar *gramRBracket = [[Grammar alloc] init];
                gramRBracket.code = word;
                gramRBracket.data = word;
                gramRBracket.expr = word;
                __move(self.tempGrammaStack, gramRBracket);
                
                if (i == __EOF(stat)) {
                    dealWithEnding = YES;
                    break;
                }
            }
            else{
                if (!recordSTR&&[word isEqualToString:@" "]) {
                    continue;
                }
                
                [cap cat:word];
                
                if (i == __EOF(stat)) {
                    dealWithEnding = YES;
                    break;
                }
            }
        }
    }
    
    if (dealWithEnding) {
        if (cap.length > 0) {
            NSInteger eof = cap.length - 1;
            Grammar *g = __wReduceByRule(self.tempGrammaStack,cap,@")",0); ///如果stat结束部位')',那只可能为属性,补充')'占位
            [cap clean];
            __move(self.tempGrammaStack, g);
            __reduce(self.tempGrammaStack,stat,&eof);
        }
        
        Grammar *r = __produceGrammar(self.tempGrammaStack);
        __move(self.gramma4OperatorStack, r);
        
        while (![self.operatorStack isEmpty]) {
            Grammar *top  = [self.operatorStack pop];
            NSString *topOp = [top.data copy];
            
            if (__is_unary_operator(topOp)) {
                Grammar *I = [self.gramma4OperatorStack pop];
                __unaryOperation(self.gramma4OperatorStack,I.data, topOp);
                
                if ([topOp isEqualToString:@"-"]) {  //change - to +
                    Grammar *add = [[Grammar alloc] init];
                    add.code = @"+";
                    add.data = @"+";
                    add.expr = @"+";
                    __move(self.operatorStack, add);
                }
            }
            else{
                Grammar *I2 = [self.gramma4OperatorStack pop];
                Grammar *I1 = [self.gramma4OperatorStack pop];
                __binocularOperation(self.gramma4OperatorStack,I1,I2,topOp);
            }
        }
        
        *returnIndex = __EOF(stat);
    }
    
    return __produceGrammar(self.gramma4OperatorStack);
}

static inline NSInteger __nearestLeftBracketInStack(__stack *stack){
    for (int i = 0; i < [stack size]; ++i) {
        Grammar *op = [stack get:i];
        if ([op.code isEqualToString:@"("]) {
            if (op.data2) {
                return [op.data2 integerValue];
            }
            
        }
    }
    
    return _codeNotFound;
}


static inline void __unaryOperation(__stack *moveStack,id obj,NSString *op){
    id newData;
    if ([op isEqualToString:@"!"]) {
        if (obj) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                ///just covert to integer and !
                newData = @(![obj integerValue]);
            }
            else{
                newData = nil;
            }
        }
        else{
            newData = _seatObj;
        }
    }
    else if ([op isEqualToString:@"~"]){
        if ([obj isKindOfClass:[NSNumber class]]) {
            newData = @(~[obj integerValue]);
        }
        else{
            @throw __exception(@"clay", @"operator '~' must be acted on NSNumber type", nil);
        }
    }
    else if ([op isEqualToString:@"++"]){
        if ([obj isKindOfClass:[NSNumber class]]) {
            newData = @([obj integerValue]+1);
        }
        else{
            @throw __exception(@"clay",@"operator '++' must be acted on NSNumber type",nil);
        }
    }
    else if ([op isEqualToString:@"--"]){
        if ([obj isKindOfClass:[NSNumber class]]) {
            newData = @([obj integerValue]-1);
        }
        else{
            @throw __exception(@"clay", @"operator '--' must be acted on NSNumber type", nil);
        }
    }
    else if ([op isEqualToString:@"-"]){
        if ([obj isKindOfClass:[NSNumber class]]) {
            newData = @(-[obj integerValue]);
        }
        else{
            @throw __exception(@"clay", @"operator '-' must be acted on NSNumber type", nil);
        }
    }
    
    Grammar *unaryR = [[Grammar alloc] init];
    unaryR.code = @"I";
    unaryR.data = newData;
    __move(moveStack, unaryR);
}

static inline void __binocularOperation(__stack *moveStack, Grammar *g1,Grammar *g2,NSString *op){
    id newData;
    if ([op isEqualToString:@"+"]) {
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]) {
            NSNumber *n1 = g1.data;
            NSNumber *n2 = g2.data;
            
            __get_value_from_nsnumber(1)
            __get_value_from_nsnumber(2)
            
            newData = @((d1+f1+i1)+(d2+f2+i2));
        }
    }
    else if ([op isEqualToString:@"-"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]) {
            NSNumber *n1 = g1.data;
            NSNumber *n2 = g2.data;
            
            __get_value_from_nsnumber(1)
            __get_value_from_nsnumber(2)
            
            newData = @((d1+f1+i1)-(d2+f2+i2));
        }
    }
    else if ([op isEqualToString:@"*"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]) {
            NSNumber *n1 = g1.data;
            NSNumber *n2 = g2.data;
            
            __get_value_from_nsnumber(1)
            __get_value_from_nsnumber(2)
            
            newData = @((d1+f1+i1)*(d2+f2+i2));
        }
    }
    else if ([op isEqualToString:@"/"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]) {
            NSNumber *n1 = g1.data;
            NSNumber *n2 = g2.data;
            
            __get_value_from_nsnumber(1)
            __get_value_from_nsnumber(2)
            
            newData = @((d1+f1+i1)/(d2+f2+i2));
        }
    }
    else if ([op isEqualToString:@"%"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]) {
            NSNumber *n1 = g1.data;
            NSNumber *n2 = g2.data;
            
            __get_value_from_nsnumber(1)
            __get_value_from_nsnumber(2)
            
            newData = @((i1)%(i2));
        }
    }
    else if ([op isEqualToString:@"="]){
        if (g1.data2&&g1.data3) {
            [g1.data2 setValue:g2.data
                          forKey:g1.data3];
            return;
        }
    }
    else if ([op isEqualToString:@"=="]){
        if ([g1.data isKindOfClass:[NSString class]]
            &&[g2.data isKindOfClass:[NSString class]]) {
            newData = [g1.data isEqualToString:g2.data] ? @(YES) : @(NO);
        }
        else if ([g1.data isKindOfClass:[NSNumber class]]
                 &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = [g1.data compare:g2.data]==NSOrderedSame ? @(YES) : @(NO);
        }
        else{
            newData = (g1.data == g2.data)?@(YES):@(NO);
        }
    }
    else if ([op isEqualToString:@"<"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = ([g1.data compare:g2.data] == NSOrderedAscending) ? @(YES) : @(NO);
        }
    }
    else if ([op isEqualToString:@"<="]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = ([g1.data compare:g2.data]==NSOrderedAscending || [g1.data compare:g2.data]==NSOrderedSame) ? @(YES) : @(NO);
        }
    }
    else if ([op isEqualToString:@">"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = ([g1.data compare:g2.data]==NSOrderedDescending) ? @(YES) : @(NO);
        }
    }
    else if ([op isEqualToString:@">="]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = ([g1.data compare:g2.data]==NSOrderedDescending || [g1.data compare:g2.data]==NSOrderedSame) ? @(YES) : @(NO);
        }
    }
    else if ([op isEqualToString:@"!="]
             ||[op isEqualToString:@"<>"]){
        if ([g1.data isKindOfClass:[NSNumber class]]
            &&[g2.data isKindOfClass:[NSNumber class]]){
            newData = ([g1.data compare:g2.data]!=NSOrderedSame) ? @(YES) : @(NO);
        }
    }
    else if ([op isEqualToString:@"&&"]){
        newData = (g1.data && g2.data) ? @(YES) : @(NO);
    }
    else if ([op isEqualToString:@"||"]){
        newData = (g1.data || g2.data) ? @(YES) : @(NO);
    }
    
    if (newData) {
        Grammar *r = [[Grammar alloc] init];
        r.code = @"I";
        r.data = newData;
        __move(moveStack, r);
    }
}


static inline void __treeBranch(NSString *key,  //查找head节点的关键词
                                id /*nullable*/ instance,   //开始节点的实例对象
                                Grammar *g, //需要添加到Tree的Grammar
                                NSString *stat, //解析语句
                                NSInteger *curIndex,    //语句解析到达位置
                                NSMutableArray *newGrammars, //继续解析Grammar数组
                                BOOL isPropertyInstance //是否是属性规约的结果
                                ){
    CTNode *head = [Clay_Tree head:key];
    if (head) {
        NSMutableArray *gArray;
        [Clay_Tree process:head
                  instance:instance
                      stat:stat
                startIndex:curIndex
                    gArray:&gArray];
        for (NSInteger j = gArray.count - 1;  j >= 0; --j) { [newGrammars addObject:gArray[j]]; }
    }
    else{
//        if (!isPropertyInstance) {
//            
//        }
        *curIndex -= 1;
        [Clay_Tree setHead:g];
        Grammar *gP = [[Grammar alloc] init];
        gP.code = @".";
        gP.data = @".";
        gP.expr = @".";
        [Clay_Tree append:gP to:[Clay_Tree head:[Clay_Tree calcKey:g]]];
        [newGrammars addObject:g];
    }
}

- (id)produceGrammar{
    if ([self.gramStack size]>0){
        Grammar *g = [self.gramStack pop];
        [self.gramStack clean];
        return g;
    }
    else{
        [self.gramStack clean];
    }
    
    return nil;
}

static inline id __produceGrammar(__stack *stack){
    if ([stack size]>0){
        Grammar *g = [stack pop];
        [stack clean];
        return g;
    }
    else{
        [stack clean];
    }
    
    return nil;
}

- (id)produceInstance:(Grammar *)grammar{
    
    if (grammar) {
        if ([grammar.code isEqualToString:@"I"]) {
            return grammar.data;
        }
    }
    return  nil;
}

#define __is_left_I(left) ([left isEqualToString:@"I"])
#define __is_left_C(left) ([left isEqualToString:@"C"])
#define __is_left_A(left) ([left isEqualToString:@"A"])
#define __is_left_S(left) ([left isEqualToString:@"S"])

static NSInteger _reduceCount = 0;
static NSInteger _wasteCount = 0;
static NSInteger _tempReduceCount = 0;
static inline void __reduceStack(__stack *stack, NSString *stat, NSInteger *curIndex){
    if (stack.flag == 1) {
        NSLog(@"> Temp Reduce Count %ld",++_tempReduceCount);
    }
    
    
    NSLog(@"> Reduce Count %ld",++_reduceCount);
    
    for (; ;) {
        
        NSString *r = @"";
        NSMutableArray *expr = [[NSMutableArray alloc] init];
        BOOL breakReduce = YES;
        
        for (int i = 0; i < [stack size]; ++i) {
            
            Grammar *gram = [stack get:i];
            
            if (i == 0) {
                if (!([gram.code isEqualToString:@"P"] || [gram.code isEqualToString:@"STR"] || [gram.code isEqualToString:@"NUM"] || [gram.code isEqualToString:@")"])) {
                    break;
                }
            }
            
            
            r = [r lCat:gram.code];
            [expr insertObject:gram atIndex:0];
            
            NSString *reduceCode  = _nfDict[r];
            
            if (reduceCode) {
                
                NSMutableArray *newGrammars = [[NSMutableArray alloc] init];
                
                #define __just_add_origin_grammar_to_keep_reduce(expr) [newGrammars addObject:expr]
                #define __malloc_grammar_data1(__index__,__data__) \
                        Grammar *g##__index__ = [[Grammar alloc] init];\
                        g##__index__.code = reduceCode;\
                        g##__index__.data = __data__;
                #define __malloc_grammar_data2(__index__,__data__,__data2__) \
                        Grammar *g##__index__ = [[Grammar alloc] init];\
                        g##__index__.code = reduceCode;\
                        g##__index__.data = __data__;\
                        g##__index__.data2 = __data2__;
                #define __malloc_grammar_data3(__index__,__data__,__data2__,__data3__) \
                        Grammar *g##__index__ = [[Grammar alloc] init];\
                        g##__index__.code = reduceCode;\
                        g##__index__.data = __data__;\
                        g##__index__.data2 = __data2__;\
                        g##__index__.data3 = __data3__;
                
                if (__is_left_A(reduceCode)) {
                    if ([r isEqualToString:@"(I)"]) {
                        __just_add_origin_grammar_to_keep_reduce(expr[0]);
                        
                        Grammar *I = (Grammar *)expr[1];

                        __malloc_grammar_data1(1,I.data);
                        
                        NSMutableArray *newData = [NSMutableArray arrayWithObjects:g1,nil];
                        
                        __malloc_grammar_data1(2,newData);
                        [newGrammars addObject:g2];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[2]);
                    }
                    else if ([r isEqualToString:@",I)"]) {
                        __just_add_origin_grammar_to_keep_reduce(expr[0]);
                        
                        Grammar *I = (Grammar *)expr[1];
                        
                        __malloc_grammar_data1(1, I.data);
                        
                        NSMutableArray *newData = [NSMutableArray arrayWithObjects:g1,nil];
                        __malloc_grammar_data1(2,newData);
                        
                        [newGrammars addObject:g2];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[2]);
                    }
                    else if ([r isEqualToString:@",I,A)"]){
                        __just_add_origin_grammar_to_keep_reduce(expr[0]);
                        
                        Grammar *I = (Grammar *)expr[1];
                        
                        __malloc_grammar_data1(1, I.data);
                        
                        Grammar *A = (Grammar *)expr[3];
                        
                        NSMutableArray *aList = [NSMutableArray arrayWithArray:A.data];
                        [aList insertObject:g1 atIndex:0];
                        __malloc_grammar_data1(2,aList);
                        
                        [newGrammars addObject:g2];

                        __just_add_origin_grammar_to_keep_reduce(expr[4]);
                    }
                    else if ([r isEqualToString:@"(I,A)"]){
                        __just_add_origin_grammar_to_keep_reduce(expr[0]);
                        
                        Grammar *I = (Grammar *)expr[1];
                        
                         __malloc_grammar_data1(1, I.data);
                        
                        Grammar *A = (Grammar *)expr[3];
                        
                        NSMutableArray *aList = [NSMutableArray arrayWithArray:A.data];
                        [aList insertObject:g1 atIndex:0];
                        __malloc_grammar_data1(2,aList);
                        
                        [newGrammars addObject:g2];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[4]);
                    }
                    else if ([r isEqualToString:@"MS:I)"]){
                        
                        Grammar *MS = ((Grammar *)expr[0]);
                        Grammar *I = ((Grammar *)expr[2]);
                        
                        __malloc_grammar_data2(1, I.data,MS.data);
                        
                        NSMutableArray *newData = [NSMutableArray arrayWithObjects:g1,nil];
                        __malloc_grammar_data1(2, newData);
                        [newGrammars addObject:g2];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[3]);
                    }

                    else if ([r isEqualToString:@"MS:I,A)"]){
                        Grammar *MS = ((Grammar *)expr[0]);
                        Grammar *I = ((Grammar *)expr[2]);
                        Grammar *A = ((Grammar *)expr[4]);
                        
                        __malloc_grammar_data2(1, I.data,MS.data);
                        
                        NSMutableArray *aList = [NSMutableArray arrayWithArray:A.data];
                        [aList insertObject:g1 atIndex:0];
                        __malloc_grammar_data1(2, aList);
                        [newGrammars addObject:g2];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[5]);
                    }
                }
                else if (__is_left_I(reduceCode)){
                    if ([r isEqualToString:@"STR"]) {
                        __malloc_grammar_data1(1, ((Grammar *)expr[0]).data);
                        
//                        __treeBranch(@"NSString",
//                                     ((Grammar *)expr[0]).data,
//                                     g1,
//                                     stat,
//                                     curIndex,
//                                     newGrammars);
                        
                        [newGrammars addObject:g1];
                    }
                    else if ([r isEqualToString:@"NUM"]) {
                        __malloc_grammar_data1(1, ((Grammar *)expr[0]).data);
                        
//                        __treeBranch(@"NSNumber",
//                                     ((Grammar *)expr[0]).data,
//                                     g1,
//                                     stat,
//                                     curIndex,
//                                     newGrammars);
                        
                        [newGrammars addObject:g1];
                    }
                    else if ([r isEqualToString:@"I.P"]){
                        Grammar *I = ((Grammar *)expr[0]);
                        Grammar *P = ((Grammar *)expr[2]);
                        
                        id newData;
                        if ([I.data isKindOfClass:[NSValue class]]) {
                            const char *objCType = ((NSValue *)I.data).objCType;
                            
                            if (0 == strcmp(objCType, @encode(CGRect))){
                                CGRect rect = [I.data CGRectValue];
                                
                                if ([P.data isEqualToString:@"size"]) {
                                    newData = [NSValue valueWithCGSize:rect.size];
                                }
                                else if ([P.data isEqualToString:@"origin"]){
                                    newData = [NSValue valueWithCGPoint:rect.origin];
                                }
                            }
                            else if (0 == strcmp(objCType, @encode(CGSize))){
                                CGSize size = [I.data CGSizeValue];
                                
                                if ([P.data isEqualToString:@"width"]) {
                                    newData = [NSNumber numberWithFloat:size.width];
                                }
                                else if ([P.data isEqualToString:@"height"]){
                                    newData = [NSNumber numberWithFloat:size.height];
                                }
                            }
                            else if (0 == strcmp(objCType, @encode(CGPoint))){
                                CGPoint point = [I.data CGPointValue];
                                
                                if ([P.data isEqualToString:@"x"]) {
                                    newData = [NSNumber numberWithFloat:point.x];
                                }
                                else if ([P.data isEqualToString:@"y"]){
                                    newData = [NSNumber numberWithFloat:point.y];
                                }
                            }
                        }
                        else if ([I.data isKindOfClass:[NSArray class]]){
                            if ([P.data isEqualToString:@"count"]){
                                newData = [NSNumber numberWithInteger:[((NSArray *)I.data) count]];
                            }
                        }
                        else{
                            ///todo: fix UIColor
                            ///http://www.cnblogs.com/smileEvday/archive/2012/06/05/UIColor_CIColor_CGColor.html
                            newData = [I.data valueForKey:P.data];
                        }
                        
                        __malloc_grammar_data3(1, newData, I.data, P.data)
                        
                        if (newData){ // if newData is nil self.p = v;
                            *curIndex += 1;
                            __treeBranch(NSStringFromClass([newData class]),
                                         newData,
                                         g1,
                                         stat,
                                         curIndex,
                                         newGrammars,
                                         YES);
                        }
                        else{
                            [newGrammars addObject:g1];
                        }
                       
                    }
                    else if ([r isEqualToString:@"I.IM(S)"]){
                        Grammar *I = ((Grammar *)expr[0]);
                        Grammar *IM = ((Grammar *)expr[2]);
                        Grammar *S = ((Grammar *)expr[4]);
                        
                        SEL sel = __getInvokeSel(IM.data, ((Grammar *)S.data).data);
                    
                        id newData;
                        if ([I.data isKindOfClass:[Clay_Super class]]){
                            
                            Method selfMethod = class_getInstanceMethod([((Clay_Super *)I.data).instance class], sel);
                            Method superMethod = class_getInstanceMethod(((Clay_Super *)I.data).superClass, sel);
                            
                            if (superMethod && selfMethod != superMethod) { // Super's got what you're looking for
                                IMP selfMethodImp = method_getImplementation(selfMethod);
                                IMP superMethodImp = method_getImplementation(superMethod);
                                method_setImplementation(selfMethod, superMethodImp);
                                
                                newData = (__bridge id)(__invoke(((Clay_Super *)I.data).instance, sel, ((Grammar *)S.data).data));
                                
                                method_setImplementation(selfMethod, selfMethodImp); // Swap back to self's original method
                            }
                        }
                        else{
                            newData = (__bridge id)(__invoke(I.data,sel, ((Grammar *)S.data).data));
                        }
                        
                        __malloc_grammar_data1(1, newData);
                        
                        
                        *curIndex += 1;
                        __treeBranch(NSStringFromClass([newData class]),
                                     newData,
                                     g1,
                                     stat,
                                     curIndex,
                                     newGrammars,
                                     NO);
                    }
                    else if ([r isEqualToString:@"I.IM()"]){
                        Grammar *I = ((Grammar *)expr[0]);
                        Grammar *IM = ((Grammar *)expr[2]);
                        
                        SEL sel = NSSelectorFromString(IM.data);
                        
                        id newData;
                        if ([I.data isKindOfClass:[Clay_Super class]]){
                            
                            Method selfMethod = class_getInstanceMethod([((Clay_Super *)I.data).instance class], sel);
                            Method superMethod = class_getInstanceMethod([((Clay_Super *)I.data).instance superclass], sel);
                            
                            if (superMethod && selfMethod != superMethod) { // Super's got what you're looking for
                                IMP selfMethodImp = method_getImplementation(selfMethod);
                                IMP superMethodImp = method_getImplementation(superMethod);
                                method_setImplementation(selfMethod, superMethodImp);
                                
                                newData = (__bridge id)(__invoke(((Clay_Super *)I.data).instance, sel, nil));
                                
                                method_setImplementation(selfMethod, selfMethodImp); // Swap back to self's original method
                            }else{
                                newData = (__bridge id)(__invoke(((Clay_Super *)I.data).instance, sel, nil));
                            }
                        }
                        else{
                            newData = (__bridge id)(__invoke(I.data, sel, nil));
                        }
                        
                        __malloc_grammar_data1(1, newData);
                        
                        *curIndex += 1;
                        __treeBranch(NSStringFromClass([newData class]),
                                     newData,
                                     g1,
                                     stat,
                                     curIndex,
                                     newGrammars,
                                     NO);
                    }
                    else if ([r isEqualToString:@"C.SM(S)"]){
                        Grammar *C = ((Grammar *)expr[0]);
                        Grammar *SM = ((Grammar *)expr[2]);
                        Grammar *S = ((Grammar *)expr[4]);
                        
                        SEL sel = __getInvokeSel(SM.data, ((Grammar *)S.data).data);
                        id newData = (__bridge id)(__invoke(C.data, sel, ((Grammar *)S.data).data));
                        
                        __malloc_grammar_data1(1, newData);
                        
                        *curIndex += 1;
                        __treeBranch(NSStringFromClass([newData class]),
                                     newData,
                                     g1,
                                     stat,
                                     curIndex,
                                     newGrammars,
                                     NO);
                    
                    }
                    else if ([r isEqualToString:@"C.SM()"]){
                        Grammar *C = ((Grammar *)expr[0]);
                        Grammar *SM = ((Grammar *)expr[2]);
                        
                        SEL sel = NSSelectorFromString(SM.data);
                        
                        id newData = (__bridge id)(__invoke(C.data, sel, nil));
                        
                        __malloc_grammar_data1(1, newData);
                        
                        *curIndex += 1;
                        __treeBranch(NSStringFromClass([newData class]),
                                     newData,
                                     g1,
                                     stat,
                                     curIndex,
                                     newGrammars,
                                     NO);
                    }
                    else if ([r isEqualToString:@"C(S)"]){
                        Grammar *C = ((Grammar *)expr[0]);
                        Grammar *S = ((Grammar *)expr[2]);
                        
                        id newData;
                        if (C.data2
                            &&[C.data2 isKindOfClass:[NSString class]]) {
                            
                            if ([C.data2 isEqualToString:Clay_Struct]){
                                 newData = (__bridge id)(__invokeStruct([C.data alloc], ((Grammar *)S.data).data));
                            }
                            else if ([C.data2 isEqualToString:Clay_C]){
                                newData = (__bridge id)(__invokeC([C.data alloc], ((Grammar *)S.data).data));
                            }
                            else{
                                SEL sel = __getInvokeSel(@"", ((Grammar *)S.data).data);
                                newData = (__bridge id)(__invoke([C.data alloc], sel, ((Grammar *)S.data).data));
                            }
                           
                        }
                        else{
                            SEL sel = __getInvokeSel(@"", ((Grammar *)S.data).data);
                            newData = (__bridge id)(__invoke([C.data alloc], sel, ((Grammar *)S.data).data));
                        }
                        
                        __malloc_grammar_data1(1, newData);
                        
                        [newGrammars addObject:g1];
                        
                    }
                    else if ([r isEqualToString:@"C()"]){
                        Grammar *C = ((Grammar *)expr[0]);
                        
                        id newData;
                        if (C.data2
                            &&[C.data2 isKindOfClass:[NSString class]]) {
                            if ([C.data2 isEqualToString:Clay_Struct]){
                                newData = (__bridge id)(__invokeStruct([C.data alloc], nil));
                            }
                            else if ([C.data2 isEqualToString:Clay_C]){
                                newData = (__bridge id)(__invokeC([C.data alloc], nil));
                            }
                            else{
                                newData = [[C.data alloc] init];
                            }
                        }
                        else{
                            newData = [[C.data alloc] init];
                        }
                        
                        __malloc_grammar_data1(1,newData);
                        
                        [newGrammars addObject:g1];
                    }
                }
                else if (__is_left_S(reduceCode)){
                    
                    if ([r isEqualToString:@"(A)"]) {
                        __just_add_origin_grammar_to_keep_reduce(expr[0]);
                        
                        __malloc_grammar_data1(1,expr[1]);

                        [newGrammars addObject:g1];
                        
                        __just_add_origin_grammar_to_keep_reduce(expr[2]);
                    }
                }
                
                if (newGrammars.count > 0) {
                    [stack popToIndex:i];
                    for (int j = 0; j < newGrammars.count; ++j) {[stack push:newGrammars[j]];}
                }
                breakReduce = NO;
                break;
            }
        }
        if (breakReduce) { NSLog(@"> Waste Count %ld",++_wasteCount); break; }
    }
}



static inline Grammar *__wReduceByRule(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    if (cap.length == 0) return nil;
    
    Grammar *gram = nil;
    
    #define __case_r(__n__)\
        if ((gram = __r##__n__(stack, cap, stat, curIndex))){\
        gram.expr = cap;\
        return gram;\
    }
    
    __case_r(7)
    __case_r(1)
    __case_r(3)
    __case_r(4)
    __case_r(5)
    __case_r(6)
    
    return nil;
}

static inline BOOL __isClass(NSString *s){ return NSClassFromString(s); }

static inline Grammar *__r1(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    NSString *nClass = cap;
    NSString *csClass = [NSString stringWithFormat:@"%@%@",Clay_Struct,cap];
    NSString *ccClass = [NSString stringWithFormat:@"%@%@",Clay_C,cap];
    NSString *coClass = [NSString stringWithFormat:@"%@%@",Clay_Object,cap];
    Class c;
    NSString *t;
    BOOL isClass;
    char curChar = [stat characterAtIndex:curIndex];
    
    if ( [stack isEmpty] || curChar == '.' || curChar == '(' ){
        if ((isClass = __isClass(nClass))) {
            c = NSClassFromString(nClass);
        }
        else if ((isClass = __isClass(csClass))){
            c = NSClassFromString(csClass);
            t = Clay_Struct;
        }
        else if ((isClass = __isClass(ccClass))){
            c = NSClassFromString(ccClass);
            t = Clay_C;
        }
        else if ((isClass = __isClass(coClass))){
            c = NSClassFromString(coClass);
            t = Clay_Object;
        }
        
        if (isClass) {
            Grammar *gram = [[Grammar alloc] init];
            gram.code = @"C";
            gram.data = c;
            gram.data2 = t;
            
            [Clay_Tree setHead:gram];
            
            
            Grammar *gB = [[Grammar alloc] init];
            gB.code = [NSString stringWithFormat:@"%c",curChar];
            gB.data = [NSString stringWithFormat:@"%c",curChar];
            gB.expr = [NSString stringWithFormat:@"%c",curChar];
            [Clay_Tree append:gB to:[Clay_Tree head:[Clay_Tree calcKey:gram]]];
            
        
            return gram;
        }
    }

    return nil;
}

static inline Grammar *__r3(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    char curChar = [stat characterAtIndex:curIndex];
    if (curChar == '(') {
        if ([stack size]>=2
            &&[((Grammar *)[stack get:0]).code isEqualToString:@"."]
            &&[((Grammar *)[stack get:1]).code isEqualToString:@"C"]) {
            Grammar *gram = [[Grammar alloc] init];
            gram.code = @"SM";
            gram.data =[cap copy];
            if (curIndex + 1 < stat.length) {
                if ([stat characterAtIndex:curIndex + 1] == ')') {
                    gram.data2 = __NO_PARAM__;
                }
            }
            
            CTNode *head = [Clay_Tree head:[Clay_Tree calcKey:(Grammar *)[stack get:1]]];
            if (head) {
                [Clay_Tree append:gram to:head];
            }
            
            return gram;
        }
    }
    
    return nil;
}

static inline Grammar *__r4(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    char curChar = [stat characterAtIndex:curIndex];
    if (curChar == '(') {
        if ([stack size]>=2
            &&[((Grammar *)[stack get:0]).code isEqualToString:@"."]
            &&[((Grammar *)[stack get:1]).code isEqualToString:@"I"]) {
            Grammar *gram = [[Grammar alloc] init];
            gram.code = @"IM";
            gram.data =[cap copy];
            if (curIndex + 1 < stat.length) {
                if ([stat characterAtIndex:curIndex + 1] == ')') {
                    gram.data2 = __NO_PARAM__;
                }
            }
            
            CTNode *head = [Clay_Tree head:[Clay_Tree calcKey:(Grammar *)[stack get:1]]];
            if (head) {
                [Clay_Tree append:gram to:head];
            }
            
            return gram;
        }
    }
    
    return nil;
}

static inline Grammar *__r5(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    char curChar = [stat characterAtIndex:curIndex];
    if (curChar == '.' || curChar == ')' || curChar == '=' || curChar == ','
        || _operators[[NSString stringWithFormat:@"%c",curChar]]) {
        if ([stack size]>=2
            &&[((Grammar *)[stack get:0]).code isEqualToString:@"."]
            &&[((Grammar *)[stack get:1]).code isEqualToString:@"I"]) {
            Grammar *gram = [[Grammar alloc] init];
            gram.code = @"P";
            gram.data =[cap copy];
            
            CTNode *head = [Clay_Tree head:[Clay_Tree calcKey:(Grammar *)[stack get:1]]];
            if (head) {
                [Clay_Tree append:gram to:head];
            }
            
            return gram;
        }
    }
    
    return nil;
}

static inline Grammar *__r6(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    char curChar = [stat characterAtIndex:curIndex];
    if (curChar == ':') {
        Grammar *gram = [[Grammar alloc] init];
        gram.code = @"MS";
        gram.data =[cap copy];
        return gram;
    }
    
    return nil;
}

static inline Grammar *__r7(__stack *stack, NSString *cap, NSString *stat, NSInteger curIndex){
    NSScanner *scanner = [[NSScanner alloc] initWithString:cap];
    
    #define __scan_str(__t__,__m__,__c__)\
        __t__ val##__m__;\
        if ([scanner scan##__m__:&val##__m__] && [scanner isAtEnd]){\
            Grammar *gram = [[Grammar alloc] init];\
            gram.code = @"NUM";\
            gram.data = [NSNumber numberWith##__m__:val##__m__];\
            gram.data2 = [NSString stringWithFormat:@"%c",__c__];\
            return gram;\
        }

    __scan_str(double,Double,_C_DBL);
    __scan_str(float,Float,_C_FLT);
    #if defined(__arm64__)
        __scan_str(NSInteger,Integer,_C_LNG_LNG);
    #else
        __scan_str(NSInteger,Integer,_C_LNG);
    #endif
    
    return nil;
}

static inline SEL __getInvokeSel(NSString *prefix,NSMutableArray *args){
    NSMutableString *sel = [prefix mutableCopy];
    if (sel.length>0 && args.count) {[sel cat:@":"];}
    
    for (int i = 0; i < args.count; ++i) {
        Grammar *a = args[i];
        if (a.data2) {
            [sel cat:a.data2];
            [sel cat:@":"];
        }
    }
    
    return NSSelectorFromString(sel);
}

static inline void __OCBlock_Call_JSFunction(NSString *methodName,NSArray *args){
    NSString *func = [[NSString alloc] initWithFormat:@"%@['%@']",JS_METHOD_MAP,methodName];
    JSValue *method = [[Clay_VMExecutor shared]._jsContext evaluateScript:func];
    [method callWithArguments:args.count?args:nil];
}

static inline void *__invokeC(id sender,NSMutableArray *args){
    return (__bridge void *)([sender performSelector:@selector(callC:) withObject:args]);
}
                                                   
static inline void *__invokeStruct(id sender,NSMutableArray *args){
    NSString *sel = @"";
    for (int i = 0; i < args.count; ++i) { sel = [sel cat:[NSString stringWithFormat:@"p%d:",i]];}
    return __invoke(sender, NSSelectorFromString(sel), args);
}


static inline id __genBlock(NSString *methodName){
    id block = nil;
    NSString *argDesc = [methodName substringFromIndex:methodName.length-2];
    if ([argDesc hasPrefix:@"a"]) {
        NSInteger argCount = [[argDesc substringFromIndex:argDesc.length-1] integerValue];
        switch (argCount) {
            case 0:{
                block = ^{ __OCBlock_Call_JSFunction(methodName,nil); };
            }
                break;
            case 1:{
                block = ^(id a){
                    NSMutableArray *args = [[NSMutableArray alloc] init];
                    [args addObject:a ? a:[NSNull null]];
                    __OCBlock_Call_JSFunction(methodName,args);
                    
                };
            }
                break;
            case 2:{
                block = ^(id a,id b){
                    NSMutableArray *args = [[NSMutableArray alloc] init];
                    [args addObject:a ? a:[NSNull null]];
                    [args addObject:b ? b:[NSNull null]];
                    __OCBlock_Call_JSFunction(methodName,args);
                    
                };
            }
                break;
            case 3:{
                block = ^(id a,id b,id c){
                    NSMutableArray *args = [[NSMutableArray alloc] init];
                    [args addObject:a ? a:[NSNull null]];
                    [args addObject:b ? b:[NSNull null]];
                    [args addObject:c ? c:[NSNull null]];
                    __OCBlock_Call_JSFunction(methodName,args);
                };
            }
                break;
            case 4:{
                block = ^(id a,id b,id c,id d){
                    NSMutableArray *args = [[NSMutableArray alloc] init];
                    [args addObject:a ? a:[NSNull null]];
                    [args addObject:b ? b:[NSNull null]];
                    [args addObject:c ? c:[NSNull null]];
                    [args addObject:d ? d:[NSNull null]];
                    __OCBlock_Call_JSFunction(methodName,args);
                };
            }
                break;
            case 5:{
                block = ^(id a,id b,id c,id d,id e){
                    NSMutableArray *args = [[NSMutableArray alloc] init];
                    [args addObject:a ? a:[NSNull null]];
                    [args addObject:b ? b:[NSNull null]];
                    [args addObject:c ? c:[NSNull null]];
                    [args addObject:d ? d:[NSNull null]];
                    [args addObject:e ? e:[NSNull null]];
                    __OCBlock_Call_JSFunction(methodName,args);
                    
                };
            }
                break;
            default:
                break;
        }
    }
    
    return block;
}


static inline int _strprefix(const char *str, const char *prefix){
    int step = 0;
    size_t str_len = strlen(str);
    size_t prefix_len = strlen(prefix);
    
    if (prefix_len > str_len) return -1;
    
    while (step<prefix_len) {
        if (str[step] == prefix[step]) step++;
        else return -1;
    }
    
    return 0;
}

static inline void *__variantInvoke(id sender,SEL cmd, NSMutableArray *args){
    if (sel_isEqual(cmd, @selector(initWithFormat:)) && [sender isKindOfClass:[NSString class]]) {
        NSString *formatString = ((Grammar *)args[0]).data;
        [args removeObjectAtIndex:0];
        
        NSMutableArray *newArgs = [NSMutableArray array];
        
        for (int i = 0; i < args.count; ++i) {
            Grammar *argA = args[i];
            [newArgs addObject:argA.data];
        }
        
        NSString *returnValue = [[NSString alloc] initWithFormat:formatString,
                                 clay_va_arg(newArgs,0),
                                 clay_va_arg(newArgs,1),
                                 clay_va_arg(newArgs,2),
                                 clay_va_arg(newArgs,3),
                                 clay_va_arg(newArgs,4),
                                 clay_va_arg(newArgs,5),
                                 clay_va_arg(newArgs,6),
                                 clay_va_arg(newArgs,7),
                                 clay_va_arg(newArgs,8),
                                 clay_va_arg(newArgs,9),
                                 clay_va_arg(newArgs,10)
                                 ];
        
        return (__bridge_retained void *)(returnValue);
    }
    else if (sel_isEqual(cmd, @selector(initWithObjects:))){
        if ([sender isKindOfClass:[NSArray class]]) {
            NSMutableArray *newArgs = [NSMutableArray array];
            for (int i = 0; i < args.count; ++i) { Grammar *argA = args[i];[newArgs addObject:argA.data];}
            return  (__bridge void *)([NSArray arrayWithArray:newArgs]);
        }
        else if ([sender isKindOfClass:[NSMutableArray class]]){
            NSMutableArray *newArgs = [NSMutableArray array];
            for (int i = 0; i < args.count; ++i) { Grammar *argA = args[i];[newArgs addObject:argA.data];}
            return  (__bridge void *)([NSMutableArray arrayWithArray:newArgs]);
        }
    }
    else if (sel_isEqual(cmd, @selector(initWithObjectsAndKeys:))){
        if ([sender isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *objs = [NSMutableArray array];
            NSMutableArray *keys = [NSMutableArray array];
            
            for (int i = 0; i < args.count; ++i) {
                Grammar *argA = args[i];
                i%2==0?[objs addObject:argA.data]:[keys addObject:argA.data];
            }
            
            return  (__bridge void *)([NSDictionary dictionaryWithObjects:objs forKeys:keys]);
        }
        else if ([sender isKindOfClass:[NSMutableDictionary class]]){
            NSMutableArray *objs = [NSMutableArray array];
            NSMutableArray *keys = [NSMutableArray array];
            
            for (int i = 0; i < args.count; ++i) {
                Grammar *argA = args[i];
                i%2==0?[objs addObject:argA.data]:[keys addObject:argA.data];
            }
            
            return  (__bridge void *)([NSMutableDictionary dictionaryWithObjects:objs forKeys:keys]);
        }
    }
    
    return nil;

}

#define __is_block_argument(arg) [arg hasPrefix:@"__clay_tmp_func"]

void *__invoke(id sender,SEL cmd,NSMutableArray *args){
    void *returnValue = nil;
    if ((returnValue = __variantInvoke(sender,cmd,args))) {
        return returnValue;
    }
    
    NSMethodSignature *signature = [sender methodSignatureForSelector:cmd];
    NSInvocation *invocation  = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:sender];
    [invocation setSelector:cmd];
    
    short index = 2;
    short baseIndex = 0;
    while (baseIndex<args.count) {
        Grammar *argA = args[baseIndex++];
        id arg = argA.data;
        
        const char *type= [signature getArgumentTypeAtIndex:index];
        
        if ([arg isKindOfClass:[NSNumber class]]) {
            #define __case_nsnumber(__typeChar__,__type__,__convertType___)\
            case(__typeChar__):{\
                __type__ v = [arg __convertType___];\
                [invocation setArgument:&v atIndex:index++];\
            }\
            break;
            
            switch (type[0]) {
                    __case_nsnumber(_C_SHT, short, shortValue)
                    __case_nsnumber(_C_USHT, unsigned short, unsignedShortValue)
                    __case_nsnumber(_C_INT, int, intValue)
                    __case_nsnumber(_C_UINT,unsigned int, unsignedIntValue)
                    __case_nsnumber(_C_LNG, long, longValue)
                    __case_nsnumber(_C_ULNG,unsigned long, unsignedLongValue)
                    __case_nsnumber(_C_FLT, float, floatValue)
                    __case_nsnumber(_C_DBL, double, doubleValue)
                    __case_nsnumber(_C_ULNG_LNG, unsigned long long, unsignedLongLongValue)
                    __case_nsnumber(_C_LNG_LNG, long long, longLongValue)
                default:
                    break;
            }
            
        }
        else if ([arg isKindOfClass:[NSValue class]]){
            if (_strprefix(type,"{CGRect") == 0) {
                CGRect r = [arg CGRectValue];
                [invocation setArgument:&r atIndex:index++];
            }
            else if (_strprefix(type,"{CGPoint") == 0) {
                CGPoint p = [arg CGPointValue];
                [invocation setArgument:&p atIndex:index++];
            }
            else if (_strprefix(type,"{CGSize") == 0) {
                CGSize  s = [arg CGSizeValue];
                [invocation setArgument:&s atIndex:index++];
            }
        }
        else if ([arg isKindOfClass:[NSString class]]) {
            if (__is_block_argument(arg)) {
                arg = __genBlock(arg);
                
                ///TODO:explain it
                Block_copy((__bridge void *)arg);
            }
            [invocation setArgument:&arg atIndex:index++];
        }
        else{
            [invocation setArgument:&arg atIndex:index++];
        }
    }
    
    [invocation invoke];
    
    NSUInteger methodReturnLength = [signature methodReturnLength];
    if (methodReturnLength>0) {
        const char * typeDescription = [signature methodReturnType];
        switch (typeDescription[0]) {
            case _C_STRUCT_B:{
                
                NSValue *value = nil;
                void *buffer = (void *)malloc(methodReturnLength);
                
                #define __if_nsvalue(__type__)\
                if (0 == strcmp(typeDescription,__type__)){\
                    [invocation getReturnValue:buffer];\
                    value = [[NSValue alloc] initWithBytes:buffer objCType:__type__];\
                }
                
                __if_nsvalue(@encode(CGRect))
                else __if_nsvalue(@encode(CGPoint))
                else __if_nsvalue(@encode(CGSize))
                else __if_nsvalue(@encode(UIEdgeInsets))
                else __if_nsvalue(@encode(NSRange))
                
                free(buffer);
                
                return (__bridge_retained void*)(value);
            }
            case _C_BOOL:{
                NSNumber *value = nil;
                char *buffer = (char *)malloc(methodReturnLength);
                memset(buffer, 0, methodReturnLength);
                [invocation getReturnValue:buffer];
                value = (buffer[0] == 0 ? @(NO) : @(YES));
                free(buffer);
                return (__bridge_retained void*)(value);
            }
            #define __case_generic_type(__typeChar__,__encodeType__)\
            case __typeChar__:{\
                NSNumber *value = nil;\
                char *buffer = (char *)malloc(methodReturnLength);\
                memset(buffer, 0, methodReturnLength);\
                [invocation getReturnValue:buffer];\
                value = [[NSNumber alloc] initWithBytes:buffer objCType:__encodeType__];\
                free(buffer);\
                return (__bridge_retained void*)(value);\
            }
            
            __case_generic_type(_C_SHT, @encode(short))
            __case_generic_type(_C_USHT, @encode(unsigned short))
            __case_generic_type(_C_INT, @encode(int))
            __case_generic_type(_C_UINT,@encode(unsigned int))
            __case_generic_type(_C_LNG, @encode(long))
            __case_generic_type(_C_ULNG,@encode(unsigned long))
            __case_generic_type(_C_FLT, @encode(float))
            __case_generic_type(_C_DBL, @encode(double))
            __case_generic_type(_C_ULNG_LNG, @encode(unsigned long long))
            __case_generic_type(_C_LNG_LNG, @encode(long long))
            
            default:{
                void *returnValue = nil;
                [invocation getReturnValue:&returnValue];
                return returnValue;
            }
        }
    }
    else return nil;
}

@end
