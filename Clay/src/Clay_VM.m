//  Clay_VM.m
//  Clay
//
//  Created by ris on 5/23/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_VM.h"

#import <Clay/Clay_Help.h>
#import <Clay/Clay_CLObjects.h>
#import <Clay/Clay_Runtime.h>
#import <Clay/Clay_Define.h>
#import <objc/runtime.h>
#import <Clay/Clay_VM+Executor.h>

#import <CoreGraphics/CoreGraphics.h>

#define __clean_cap(__cap__) __cap__ = @"";
static NSString *_clsDefineNotFound = @"clsDefineNotFound_";

static NSMutableDictionary *_methodsMap = nil;
@interface  Clay_VM()

@property (nonatomic, strong) NSDictionary *_typeEncoding;
@property (nonatomic, strong) NSDictionary *_typeSize;
@property (nonatomic, assign) NSInteger _numberOfLine;
@end

@implementation Clay_VM

typedef enum {
    IMPSTr_start = 0,
    IMPSTr_returnType,
    IMPSTr_MS,
    IMPSTr_argType,
    IMPSTr_argName,
    IMPSTr_block
}IMPSTr;

typedef enum {
    BlockSTr_stat = 0,
    BlockSTr_boxedNumber = 0x0001,
    BlockSTr_boxedDictionary = 0x0002,
    BlockSTr_boxedArray = 0x0003,
    BlockSTr_boxedMask = 0x000F,
    BlockSTr_forCond = 0x0010,
    BlockSTr_ifCond = 0x0020,
    BlockSTr_elseCond = 0x0030,
    BlockSTr_whileCond = 0x0040,
    BlockSTr_switchCond = 0x0050,
    BlockSTr_caseCond = 0x0060,
    BlockSTr_defaultCond = 0x0070,
    BlockSTr_condMask = 0x00F0,
    BlockSTr_forBlock = 0x0100,
    BlockSTr_ifBlock = 0x0200,
    BlockSTr_elseBlock = 0x0300,
    BlockSTr_whileBlock = 0x0400,
    BlockSTr_switchBlock = 0x0500,
    BlockSTr_caseBlock = 0x0600,
    BlockSTr_defaultBlock = 0x0700,
    BlockSTr_blockMask = 0x0F00,
    BlockSTr_doWhile,
    BlockSTr_switch
}BlockSTr;

+ (void)initialize{
    if (self == [Clay_VM self]) {
        _methodsMap = [[NSMutableDictionary alloc] init];
    }
}

- (NSDictionary *)_typeEncoding{
    if (nil == __typeEncoding) {
#define __type_encoding_pair(__type__,__encoding__)\
@#__type__ : __encoding__
        __typeEncoding = @{
                          __type_encoding_pair(id, _CL_ID),
                          __type_encoding_pair(SEL, _CL_SEL),
                          __type_encoding_pair(char, _CL_CHR),
                          __type_encoding_pair(unsigned char, _CL_UCHR),
                          __type_encoding_pair(int, _CL_INT),
                          __type_encoding_pair(unsigned int, _CL_UINT),
                          __type_encoding_pair(short, _CL_SHT),
                          __type_encoding_pair(unsigned short,_CL_USHT),
                          __type_encoding_pair(long, _CL_LNG),
                          __type_encoding_pair(unsigned long,_CL_ULNG),
                          __type_encoding_pair(long long, _CL_LNG_LNG),
#if defined(__arm64__)
                          __type_encoding_pair(NSInteger, _CL_LNG_LNG),
#else
                          __type_encoding_pair(NSInteger, _CL_LNG),
#endif
                          __type_encoding_pair(unsigned long long,_CL_ULNG_LNG),
                          __type_encoding_pair(float,_CL_FLT),
                          __type_encoding_pair(CGFloat,_CL_FLT),
                          __type_encoding_pair(double,_CL_DBL),
                          __type_encoding_pair(BOOL,_CL_BOOL),
                          __type_encoding_pair(bool,_CL_BOOL),
                          };
    }
    
    return __typeEncoding;
}


- (NSDictionary *)_typeSize{
    if (nil == __typeSize) {
#define __type_size_pair(__encoding__,__type_size__)\
__encoding__ : @(__type_size__)
        __typeSize = @{
                      __type_size_pair(_CL_ID,sizeof(id)),
                      __type_size_pair(_CL_SEL,sizeof(SEL)),
                      __type_size_pair(_CL_CHR,sizeof(char)),
                      __type_size_pair(_CL_UCHR,sizeof(unsigned char)),
                      __type_size_pair(_CL_INT,sizeof(int)),
                      __type_size_pair(_CL_UINT,sizeof(unsigned int)),
                      __type_size_pair(_CL_SHT,sizeof(short)),
                      __type_size_pair(_CL_USHT,sizeof(unsigned short)),
                      __type_size_pair(_CL_LNG,sizeof(long)),
                      __type_size_pair(_CL_ULNG,sizeof(unsigned long)),
                      __type_size_pair(_CL_LNG_LNG,sizeof(long long)),
#if defined(__arm64__)
                      __type_size_pair(_CL_LNG_LNG,sizeof(NSInteger)),
#else
                      __type_size_pair(_CL_LNG,sizeof(NSInteger)),
#endif
                      __type_size_pair(_CL_ULNG_LNG,sizeof(unsigned long long)),
                      __type_size_pair(_CL_FLT,sizeof(float)),
                      __type_size_pair(_CL_DBL,sizeof(double)),
                      __type_size_pair(_CL_BOOL,sizeof(BOOL)),
                      };
    }
    
    return __typeSize;
}


- (void)evaluateOC:(NSString *)ocCode{
    
//    unsigned int c = 0;
//    Ivar * vars = class_copyIvarList([Test class], &c);
//    NSString *key=nil;
//    for(int i = 0; i < c; i++) {
//        Ivar thisIvar = vars[i];
//        key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];  //获取成员变量的名字
//        NSLog(@"variable name :%@", key);
//        key = [NSString stringWithUTF8String:ivar_getTypeEncoding(thisIvar)]; //获取成员变量的数据类型
//        NSLog(@"variable type :%@", key);
//        NSLog(@"variable type :%ld", ivar_getOffset(thisIvar));
//    }
//    free(vars);
    
    NSMutableDictionary *classes = [[NSMutableDictionary alloc] init];
    @try {
        
        NSString *curInterfaceKey;
        
        NSString *removeCommentCode = __removeComment(ocCode);
        
        for (NSInteger i = 0; i < removeCommentCode.length; ++i) {
            char c = [removeCommentCode characterAtIndex:i];
            
            if (c == '@'){
                if (__isKeyword(@"@interface", removeCommentCode, &i)
                    ||__isKeyword(@"@implementation", removeCommentCode, &i)) {
                    NSString *classDefine = __capClassDefine(self,removeCommentCode, &i);
                    CLClass *interface = __dealWithClassDefine(self,classDefine);
                    
                    CLClass *existInterface = classes[interface.class];
                    if (existInterface) {
                        [existInterface merge:interface];
                    }
                    else{
                        [classes setObject:interface forKey:interface.class];
                    }

                    curInterfaceKey = interface.class;
                }
                else if (__isKeyword(@"@property", removeCommentCode, &i)){
                    CLClass *interface = classes[curInterfaceKey];
                    CLProperty *p = __capProperty(self,removeCommentCode, &i);
                    [interface.properties addObject:p];
                }
                else if (__isKeyword(@"@end", removeCommentCode, &i)){
                    CLClass *interface = classes[curInterfaceKey];
                    if (interface) {
                        curInterfaceKey = nil;
                    }
                }
            }
            else if ((c == '-' || c == '+') && curInterfaceKey){
                CLIMP *imp = __capIMPSel(self,removeCommentCode,&i);
                CLClass *interface = classes[curInterfaceKey];
                imp.cls = interface.class;
                CLBlock *block = imp.block;
                BlockSTr sTr = BlockSTr_stat;
                BOOL forcedReturn = NO;
                __capIMPBlock(self,removeCommentCode, &i, &block, sTr, &forcedReturn);
                [_methodsMap setObject:imp
                                forKey:[NSString stringWithFormat:@"%@%c%@",
                                        imp.class,c,imp.sel]];
                [interface.imps addObject:imp];
            }
            else if (c == '\n'){
                self._numberOfLine++;
            }
        }
        
       
    }
    @catch (NSException *exception) {
        CLStr *symbols = [[CLStr alloc] init];
        for (int i = 0; i < exception.callStackSymbols.count; ++i) {
            [symbols cat:exception.callStackSymbols[i]];
            [symbols cat:@"\n"];
        }
        
        NSLog(@"crash at line %ld -- %@ \n%@",
              self._numberOfLine,
              [exception description],
              symbols);
    }
    @finally {
        for (NSInteger j = 0;  j < classes.allValues.count; ++j) {
            CLClass *interface = classes.allValues[j];
            NSLog(@"%@",[interface description]);
            run(self, interface);
        }
    }
}

+ (CLIMPContext *)getIMPContext:(NSInvocation *)invocation{
    id sender;
    [invocation getArgument:&sender atIndex:0];
    SEL sel;
    [invocation getArgument:&sel atIndex:0];
    CLIMP *imp = _methodsMap[[NSString stringWithFormat:@"%@-%@",NSStringFromClass([sender class]),NSStringFromSelector(sel)]];
    if (nil == imp) {
        imp = _methodsMap[[NSString stringWithFormat:@"%@+%@",NSStringFromClass([sender class]),NSStringFromSelector(sel)]];
    }
    
    if (nil == imp) { return nil; }
    
    return cl_getIMPContext(imp, invocation);
}

static inline NSString *__removeComment(NSString *ocCode){
    NSString *process = [ocCode copy];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"((?<!:)\\/\\/.*|\\/\\*(\\s|.)*?\\*\\/)" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    
    process = [regex stringByReplacingMatchesInString:process
                                              options:0
                                                range:NSMakeRange(0, process.length)
                                         withTemplate:@""];
    //process = [process stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return process;
}



static inline CLIMP * __capIMPSel(Clay_VM *this,NSString *ocCode, NSInteger *index){
    CLIMP *imp = [[CLIMP alloc] init];
    if ([ocCode characterAtIndex:*index] == '-') {
        imp.isClassMethod = NO;
    }
    else if ([ocCode characterAtIndex:*index] == '+'){
        imp.isClassMethod = YES;
    }

    IMPSTr sTr = 0;
    CLStr *cap = [[CLStr alloc] init];
    CLStr *sel = [[CLStr alloc] init];
    
    for (NSInteger i = *index + 1; i < ocCode.length; ++i){
        char c = [ocCode characterAtIndex:i];
        if (c == '(') {
            if (IMPSTr_start == sTr){
                sTr = IMPSTr_returnType;
            }
            else if (IMPSTr_argType == sTr){
                continue;
            }
        }
        else if (c == ')'){
            if (IMPSTr_returnType == sTr ) {
                //cap = [cap trim];
                /*deal with return type*/
                
                sTr = IMPSTr_MS;
            }
            else if (IMPSTr_argType == sTr){
                sTr = IMPSTr_argName;
            }
            
            [cap clean];
        }
        else if (c == ':' || c == '{'){
            if (IMPSTr_MS == sTr) {
                NSString *trimSel = [cap trim];
                [sel cat:trimSel];
                
                if (c == ':') {
                    [sel catC:c];
                }
                
                if (0 == imp.lineNo) {
                    imp.lineNo = this._numberOfLine;
                }
                
                [cap clean];
                
                sTr = IMPSTr_argType;
            }
            
            if (c == '{') {
                if (IMPSTr_argName == sTr){
                    NSString *argName = [cap trim];
                    [imp.inputs addObject:argName];
                    sTr = IMPSTr_MS;
                    
                    [cap clean];
                }
                
                *index = i+1;
                break;
            }
        }
        else if (c == '\n'){
            this._numberOfLine++;
            if (IMPSTr_argName == sTr){
                NSString *argName = [cap trim];
                [imp.inputs addObject:argName];
                sTr = IMPSTr_MS;
                
                [cap clean];
            }
        }
        else if (c == ' '){
            if (IMPSTr_argName == sTr){
                NSString *argName = [cap trim];
                [imp.inputs addObject:argName];
                sTr = IMPSTr_MS;
                
                [cap clean];
            }
        }
        else{
            [cap catC:c];
        }
    }
    
    imp.sel = sel;
    return imp;
}

typedef enum{
    CLQuotationMarkStateNone = 0x0111,
    CLQuotationMarkStateLeft = 0x0001,
    CLQuotationMarkStateRight = 0x0011
}CLQuotationMarkState;

#define mov_to_block(__sTr__) __sTr__ << 4

static inline void __capIMPBlock(Clay_VM *this,
                                 NSString *ocCode,
                                 NSInteger *index,
                                 CLBlock **block,
                                 BlockSTr sTr,
                                 BOOL *forcedReturn){
    
    if (*forcedReturn) { return; }
    
    CLStr *cap = [[CLStr alloc] init];
    NSString *cond = @"";
    CLQuotationMarkState doubleQMState = CLQuotationMarkStateNone;
    CLQuotationMarkState singleQMState = CLQuotationMarkStateNone;
    __stack *boxedStack = [[__stack alloc] init]; /*!用于处理boxed状态嵌套*/
    for (NSInteger i = *index; i < ocCode.length; ++i) {
        
        if (*forcedReturn) { return; }
        
        char c = [ocCode characterAtIndex:i];
        
        if ((doubleQMState & singleQMState) == CLQuotationMarkStateLeft) {
            if (c == '"') {
                goto DoubleQMLabel;
            }
            else if (c == '\''){
                goto SingleQMLabel;
            }
            
            [cap cat:[ocCode substringWithRange:NSMakeRange(i, 1)]];
            continue;
        }
        
        
        if (c == '\n') {
            this._numberOfLine++;
        }
        else if (c == '@'){
            [cap catC:c];
            
            if (i + 1 < ocCode.length) {
                
                if (sTr & BlockSTr_boxedMask){ [boxedStack push:@(sTr)]; }
                
                switch ([ocCode characterAtIndex:i+1]) {
                    case '(': sTr = BlockSTr_boxedNumber; //@(xxx)
                        break;
                    case '{': sTr = BlockSTr_boxedDictionary; //@{xxx}
                        break;
                    case '[': sTr = BlockSTr_boxedArray; //@[xxx]
                        break;
                    default:
                        sTr = BlockSTr_stat;
                        break;
                }
                
                if (sTr & BlockSTr_boxedMask) {
                    i++;
                    [cap catC:[ocCode characterAtIndex:i]];
                }
            }
        }
        else if (c == '"'){
            DoubleQMLabel:{
                switch (doubleQMState) {
                    case CLQuotationMarkStateNone:{
                        doubleQMState = CLQuotationMarkStateLeft;
                    }
                    break;
                    case CLQuotationMarkStateLeft:{
                        doubleQMState = CLQuotationMarkStateRight;
                        singleQMState = CLQuotationMarkStateRight;
                    }
                    break;
                    case CLQuotationMarkStateRight:{
                        doubleQMState = CLQuotationMarkStateLeft;
                    }
                    break;
                default:
                    break;
                }
            
                [cap catC:c];
            }
        }
        else if (c == '\''){
            SingleQMLabel:{
                switch (singleQMState) {
                    case CLQuotationMarkStateNone:{
                        singleQMState = CLQuotationMarkStateLeft;
                    }
                    break;
                    case CLQuotationMarkStateLeft:{
                        singleQMState = CLQuotationMarkStateRight;
                        doubleQMState = CLQuotationMarkStateRight;
                    }
                    break;
                    case CLQuotationMarkStateRight:{
                        singleQMState = CLQuotationMarkStateLeft;
                    }
                    break;
                default:
                    break;
                }
            
                [cap catC:c];
            }
        }
        else if (c == ')'){
            
            if (sTr & BlockSTr_condMask) {
                cond = [cap copy];
                [cap clean];
            }
            else if (sTr == BlockSTr_boxedNumber){
                [boxedStack isEmpty] ? sTr = BlockSTr_stat : [[boxedStack pop] integerValue];
                [cap catC:c];
            }
            else{
                [cap catC:c];
            }
        }
        else if (c == '('){
            if (sTr & BlockSTr_condMask) {
                [cap clean];
            }
            else{
                [cap catC:c];
            }
        }
        else if (c == '{'){
            CLBlock *b = nil;
            
            if (sTr & BlockSTr_condMask) {
                switch (sTr) {
                    case BlockSTr_forCond: b = [[CLBlockFor alloc] init];
                        break;
                    case BlockSTr_ifCond: b = [[CLBlockIf alloc] init];
                        break;
                    case BlockSTr_elseCond: b = [[CLBlockIf alloc] init];
                        break;
                    case BlockSTr_whileCond: b = [[CLBlockWhile alloc] init];
                        break;
                    case BlockSTr_switchCond: b = [[CLBlockSwitch alloc] init];
                        break;
                    default:
                        break;
                }
                
                if (b) {
                    b.cond = cond;
                    cond = @"";
                    
                    if ((*block).type == CLIf) { //判断当前的block是不是if类型，如果是需要取到当前的block
                        CLBlockIf *currentBranch = ((CLBlockIf *)(*block)).currentBranch;
                        
                        if (sTr == BlockSTr_elseCond) {
                            currentBranch.next = (CLBlockIf *)b;
                        }
                        else{
                            [currentBranch.codes addObject:b];
                            b.parent = *block;
                            *block = b;
                        }
                    }
                    else{
                        [(*block).codes addObject:b];
                        b.parent = *block;
                        *block = b;
                    }
                }
                
                sTr = mov_to_block(sTr);
                
                i += 1;
                __capIMPBlock(this,ocCode, &i, block,sTr,forcedReturn);
            }
        }
        else if (c == '}'){
            
            if (BlockSTr_boxedDictionary == sTr) {
                [boxedStack isEmpty] ? sTr = BlockSTr_stat : [[boxedStack pop] integerValue];
                [cap catC:c];
            }
            else if (BlockSTr_caseBlock == sTr || BlockSTr_defaultBlock == sTr){
                //判断确定是否为最后一个case，default 为固定最后一个
                //适配情况
                //  case x:
                //      xxx;
                //  }
                //  case x:{
                //          xxx;
                //      }
                //  }
                
                if (__nextIs(@"}",ocCode,&i) || BlockSTr_defaultBlock == sTr) { //switch 结尾
                    //获取switch块
                    *block = (*block).parent.parent;
                    sTr = BlockSTr_stat;
                    *index = i - 1;
                    return;
                }
                
                if (BlockSTr_caseBlock == sTr){
                    if (!(__nextIs(@"case", ocCode, &i) || __nextIs(@"default", ocCode, &i))) { //switch没有写完整 终止
                        *block = (*block).parent.parent;
                        sTr = BlockSTr_stat;
                        *index = i - 1;
                        return;
                    }
                }
                
            }
            else{
                if (BlockSTr_forBlock == sTr || BlockSTr_whileBlock == sTr || BlockSTr_switchBlock == sTr){
                    *block = (*block).parent;
                }
                else if (BlockSTr_elseBlock == sTr || BlockSTr_ifBlock == sTr){
                    if (__nextIs(@"else if", ocCode, &i)){
                        *index = i - @"else if".length - 1;
                        return;
                    }
                    else if (__nextIs(@"else", ocCode, &i)) {
                        *index = i - @"else".length - 1;
                        return;
                    }
                    else{
                        *block = (*block).parent;
                    }
                }
                *index = i;
                return;
            }
        }
        else if (c == ';'){
            if (sTr == BlockSTr_forCond) {
                [cap catC:c];
            }
            else if (sTr == BlockSTr_stat || sTr & BlockSTr_blockMask){
                /*adding stat*/
                CLBlockStat *stat = [[CLBlockStat alloc] init];
                stat.expr = cl_getExpr(cap);
                
                if ((*block).type == CLIf) {
                    [((CLBlockIf *)(*block)).currentBranch.codes addObject:stat];
                }
                else{
                    [(*block).codes addObject:stat];
                }
                
                [cap clean];
            }
        }
        else if (c == ':'){
            if (sTr == BlockSTr_caseCond || sTr == BlockSTr_defaultCond) {
                CLBlockCase *b = [[CLBlockCase alloc] init];
                b.cond = cap;
                [cap clean];
                
                if (sTr == BlockSTr_caseCond) {
                    sTr = BlockSTr_caseBlock;
                }
                else{
                    sTr = BlockSTr_defaultBlock;
                    b.isDefault = YES;
                }
                
                if ((*block).type == CLSwitch) {
                    [((CLBlockSwitch *)(*block)).caseSet addObject:b];
                    b.parent = *block;
                    *block = b;
                }
                else if ((*block).type == CLCase){
                    CLBlockSwitch *switchBlock = (CLBlockSwitch *)(*block).parent;
                    [switchBlock.caseSet addObject:b];
                    b.parent = switchBlock;
                    *block = b;
                }
                
                
                i += 1;
                __capIMPBlock(this,ocCode, &i, block,sTr,forcedReturn);
                
            }
            else{
                [cap catC:c];
            }
        }
        else if (c == ']'){
            if (sTr == BlockSTr_boxedArray) {
                [boxedStack isEmpty] ? sTr = BlockSTr_stat : [[boxedStack pop] integerValue];
            }
            [cap catC:c];
        }
        else {
            //keywords
            if (!(sTr & BlockSTr_condMask)) {
                
                BlockSTr potentialSTr = BlockSTr_stat;
                NSArray *keywordSet = nil;
                switch (c) {
                    case 'f':{ keywordSet = @[@"for"]; potentialSTr = BlockSTr_forCond; }
                        break;
                    case 'w':{ keywordSet = @[@"while"]; potentialSTr = BlockSTr_whileCond; }
                        break;
                    case 'd':{ keywordSet = @[@"default"]; potentialSTr = BlockSTr_defaultCond; }
                        break;
                    case 's':{ keywordSet = @[@"switch"]; potentialSTr = BlockSTr_switchCond; }
                        break;
                    case 'i':{ keywordSet = @[@"if"]; potentialSTr = BlockSTr_ifCond; }
                        break;
                    case 'e':{ keywordSet = @[@"else",@"else if"]; potentialSTr = BlockSTr_elseCond; }
                        break;
                    case 'c':{ keywordSet = @[@"case"]; potentialSTr = BlockSTr_caseCond; }
                        break;
                    default:
                        break;
                }
                
                if (keywordSet) {
                    BOOL isContinue = NO;
                    for (int n = 0; n < keywordSet.count; ++n) {
                        if (__isKeyword(keywordSet[n], ocCode, &i)) {
                            
                            if (potentialSTr == BlockSTr_defaultCond) {
                                if (BlockSTr_caseBlock == sTr) {
                                    sTr = potentialSTr;
                                    *block = (*block).parent;
                                    *index = --i;
                                    return;
                                }
                            }
                            else if (potentialSTr == BlockSTr_caseCond){
                                if (BlockSTr_caseBlock == sTr || BlockSTr_stat == sTr) {
                                    sTr = potentialSTr;
                                    *block = (*block).parent;
                                    *index = i;
                                    return;
                                }
                            }
                            else{
                                sTr = potentialSTr;
                                i--;
                                isContinue = YES;
                                break;
                            }
                        }
                    }
                    
                    if (isContinue) { continue; }
                }
            }
            
            [cap catC:c];
        }
    }
}


static inline BOOL __nextIs(NSString *str, NSString *ocCode, NSInteger *i){
    NSInteger index = *i + 1;
    for (; index < ocCode.length; index++) {
        if ([ocCode characterAtIndex:index] == ' ' || [ocCode characterAtIndex:index] == '\n') {
            continue;
        }
        else{
            if (index + str.length <= ocCode.length) {
                if ([[ocCode substringWithRange:NSMakeRange(index, str.length)] isEqualToString:str]) {
                    if (index + str.length == ocCode.length) {
                        *i = index + str.length;
                        return YES;
                    }
                    else{
                        if ([ocCode characterAtIndex:index + str.length] == ' '
                            ||[ocCode characterAtIndex:index + str.length] == '\n'
                            ||[ocCode characterAtIndex:index + str.length] == ';'
                            ||[ocCode characterAtIndex:index + str.length] == '(') {
                            *i = index + str.length;
                            return YES;
                        }
                        else{
                            return NO;
                        }
                    }
                }
                else{
                    return NO;
                }
            }
            else{
                return NO;
            }
        }
    }
    
    return NO;
}


static inline CLClass * __dealWithClassDefine(Clay_VM *this,NSString *classDefine){
    CLClass *interface = [[CLClass alloc] init];
    NSScanner *scanner = [[NSScanner alloc] initWithString:classDefine];
    
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    NSString *ingore;
    NSString *ivarList;
    if ([scanner scanUpToString:@":" intoString:&className]){
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@"<" intoString:&superClassName];
            if (!scanner.isAtEnd) {
                scanner.scanLocation = scanner.scanLocation + 1;
                [scanner scanUpToString:@">" intoString:&protocolNames];
                if (!scanner.isAtEnd) {
                    scanner.scanLocation = scanner.scanLocation + 2;
                    [scanner scanUpToString:@"{" intoString:&ingore];
                    if (!scanner.isAtEnd) {
                        scanner.scanLocation = scanner.scanLocation + 1;
                        [scanner scanUpToString:@"}" intoString:&ivarList];
                    }
                }
            }
        }
        else{
            scanner.scanLocation = 0;
            if ([scanner scanUpToString:@"(" intoString:&className]){
                if (!scanner.isAtEnd) {
                    scanner.scanLocation = scanner.scanLocation + 1;
                    [scanner scanUpToString:@")" intoString:&ingore];
                    if (!scanner.isAtEnd) {
                        scanner.scanLocation = scanner.scanLocation + 1;
                        [scanner scanUpToString:@"<" intoString:&ingore];
                        if (!scanner.isAtEnd) {
                            scanner.scanLocation = scanner.scanLocation + 1;
                            [scanner scanUpToString:@">" intoString:&protocolNames];
                            if (!scanner.isAtEnd) {
                                scanner.scanLocation = scanner.scanLocation + 2;
                                [scanner scanUpToString:@"{" intoString:&ingore];
                                if (!scanner.isAtEnd) {
                                    scanner.scanLocation = scanner.scanLocation + 1;
                                    [scanner scanUpToString:@"}" intoString:&ivarList];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    className = [className trim];
    className = [className stringByReplacingOccurrencesOfString:@"(" withString:@""];
    className = [className stringByReplacingOccurrencesOfString:@")" withString:@""];
    className = [className trim];
    superClassName = [superClassName trim];
    
    if (!superClassName) superClassName = @"NSObject";
    
    Class superClass = NSClassFromString(superClassName);
    if (!superClass) {
        @throw [NSException exceptionWithName:@"clay"
                                       reason:[NSString stringWithFormat:@"can not find supper class %@",superClassName]
                                     userInfo:nil];
    }
    
    if (protocolNames.length) {
        NSArray *protocols = [protocolNames componentsSeparatedByString:@","];
        for (int i = 0; i < protocols.count; ++i) {
            [interface.protocols addObject:[protocols[i] trim]];
        }
    }
    
    ivarList = [ivarList trim];
    if (ivarList.length) {
        NSArray *ivars = [ivarList split:@";"];
        for (int i = 0; i < ivars.count; ++i) {
            NSString *ivarStr = ivars[i];
            if (ivarStr.length) {
                CLIVar *ivar = __capIVar(this,ivars[i]);
                [interface.ivars setObject:ivar
                                    forKey:ivar.name];
            }
        }
    }
    
    interface.class = className;
    interface.superClass = superClassName;
    return interface;
}

static inline CLIVar *__capIVar(Clay_VM *this,NSString *ivarDeclare){
    CLIVar *ivar = [[CLIVar alloc] init];
    BOOL typeCap = NO,ptr = NO;
    CLStr *cap = [[CLStr alloc] init];
    
    ivarDeclare = [ivarDeclare trim];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<.+>)" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    ivarDeclare = [regex stringByReplacingMatchesInString:ivarDeclare
                                              options:0
                                                range:NSMakeRange(0, ivarDeclare.length)
                                         withTemplate:@""];

    
    if ([ivarDeclare containsString:@"*"]){
        ptr = YES;
        ivarDeclare = [ivarDeclare stringByReplacingOccurrencesOfString:@"*"
                                                             withString:@" "];
    }
    
   
    for (int i = 0; i < ivarDeclare.length; ++i) {
        char c = [ivarDeclare characterAtIndex:i];
        if (c == ' '){
            if (!typeCap) {
                NSString *typeEncoding = this._typeEncoding[cap];
                if (typeEncoding) {
                    if (ptr) {
                        ivar.typeEncoding = [NSString stringWithFormat:@"%@%@",_CL_PTR,typeEncoding];
                        ivar.sizeType = sizeof(id  *);
                    }
                    else{
                        ivar.typeEncoding = typeEncoding;
                        ivar.sizeType = [this._typeSize[typeEncoding] integerValue];
                    }
                }
                else{
                    ivar.typeEncoding = [NSString stringWithFormat:@"@\"%@\"",cap];
                    ivar.sizeType = sizeof(id  *);
                }
                [cap clean];
                typeCap = YES;
            }
        }
        else{
            [cap catC:c];
            if (i == ivarDeclare.length - 1) {
                ivar.name = [cap trim];
            }
        }
    }

    return  ivar;
}

static inline BOOL __isKeyword(NSString *kw, NSString *ocCode, NSInteger *index){
    if ([kw isEqualToString:@"else if"]) {
        if ((*index + @"else".length <= ocCode.length) && [[ocCode substringWithRange:NSMakeRange(*index, @"else".length)] isEqualToString:@"else"]) {
            NSInteger i = *index + @"else".length;
            for (; ; i++) {
                if ([ocCode characterAtIndex:i] == ' ' || [ocCode characterAtIndex:i] == '\n'){
                    continue;
                }
                else{
                    if ((i + @"if".length + 1 <= ocCode.length)
                        && [[ocCode substringWithRange:NSMakeRange(i, @"if".length)] isEqualToString:@"if"]
                        && ([ocCode characterAtIndex:i+@"if".length] == ' ' || [ocCode characterAtIndex:i+@"if".length] == '\n' || [ocCode characterAtIndex:i+@"if".length] == '(' || [ocCode characterAtIndex:i+@"if".length] == ':' || [ocCode characterAtIndex:i+@"if".length] == '{')) {
                        *index = i + @"if".length;
                        return YES;
                    }
                    else{ return NO; }
                }
            }
        }
    }
    else if ((*index + kw.length + 1 <= ocCode.length)
             && [[ocCode substringWithRange:NSMakeRange(*index, kw.length)] isEqualToString:kw]
             && ([ocCode characterAtIndex:*index+kw.length] == ' ' || [ocCode characterAtIndex:*index+kw.length] == '\n' || [ocCode characterAtIndex:*index+kw.length] == '(' || [ocCode characterAtIndex:*index+kw.length] == ':'|| [ocCode characterAtIndex:*index+kw.length] == '{') ) {
        *index = *index+kw.length;
        return YES;
    }
    
    return NO;
}


static inline NSString *__capClassDefine(Clay_VM *this, NSString *ocCode, NSInteger *index){
    BOOL startCapClsDefine = NO;
    CLStr *cap = [[CLStr alloc] init];
    for (NSInteger i = *index; i < ocCode.length; ++i) {
        char c = [ocCode characterAtIndex:i];
        if (c == ' ' || c == '\n'){
            
            if (c == '\n') { this._numberOfLine++; }
            
            if (startCapClsDefine) {
                [cap catC:c];
            }
            else{
                continue;
            }
        }
        else{
            
            if (c == '\n') { this._numberOfLine++; }
            
            if (startCapClsDefine){
                
                do{
                    if (c == '@') {
                        if (__nextIs(@"private", ocCode, &i)) break;
                        else if (__nextIs(@"public", ocCode, &i)) break;
                    }
                    else if (c == '}'){
                        [cap catC:c];
                        *index = i;
                        return cap;
                    }
                    else if  (c == '@' || c == '+' || c == '-'){
                        *index = i - 1;
                        return  cap;
                    }
                    else{
                        [cap catC:c];
                    }
                    
                }while (0);
            }
            else{
                startCapClsDefine = YES;
                [cap catC:c];
            }
        }
    }
    
    return _clsDefineNotFound;
}

static inline CLProperty *__capProperty(Clay_VM *this,NSString *ocCode,NSInteger *index){
    CLStr *cap = [[CLStr alloc] init];
    BOOL capType = NO,endAttr = NO,capValue = NO;
    CLProperty *p = [[CLProperty alloc] init];
    for (NSInteger i = *index; i < ocCode.length; ++i) {
        char c = [ocCode characterAtIndex:i];
        
        if (c == '(') {
            continue;
        }
        else if (c == ',' || c == ')'){
            NSString *attr = [cap trim];
            if ([attr isEqualToString:@"nonatomic"]) {
                [p.attrs addObject:@"N"];
            }
            else if ([attr isEqualToString:@"copy"]){
                [p.attrs addObject:@"C"];
            }
            else if ([attr isEqualToString:@"strong"]){
                [p.attrs addObject:@"&"];
            }
            else if ([attr isEqualToString:@"readonly"]){
                [p.attrs addObject:@"R"];
            }
            else if ([attr isEqualToString:@"weak"]){
                [p.attrs addObject:@"W"];
            }
            
            [cap clean];
            
            if (c == ')') {
                endAttr = YES;
            }
        }
        else if (c == ' '){
            if (endAttr) {
                if (!capType){
                    capType = YES;
                }
                else{
                    NSString *type = [cap trim];
                    p.T = type;
                    [cap clean];
                    capValue = YES;
                }
            }
        }
        else if (c == ';'){
            if (capValue) {
                NSString *value = [cap trim];
                if ([value hasPrefix:@"*"]) {
                    value = [value substringFromIndex:1];
                }
                
                p.V = value;
                *index = i;
                return p;
            }
        }
        else if (c == '\n'){
            this._numberOfLine++;
        }
        else{
            [cap catC:c];
        }
    }
    
    return nil;
}


@end
