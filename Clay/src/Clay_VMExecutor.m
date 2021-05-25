//
//  Clay_VMExecutor.m
//  Clay
//
//  Created by yin shen on 11/18/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay_VMExecutor.h"
#import "Clay.h"
#import "Clay_Help.h"
#import "Clay_Exception.h"
#import "Clay_Define.h"

const NSString *JS_METHOD_MAP = @"__js_method_map";
const  NSString *JS_VARIABLE_MAP = @"__js_variable_map";

static NSInteger TMP_V_INCREASE = 0;

static NSString *CLAY_REQUIRE_BEGIN = @"clay.require(\"";
static NSString *CLAY_IMPORT_BEGIN = @"clay.import(\"";
static NSString *CLAY_INCLUDE_END = @"\");";


@interface Clay_VMExecutor(){}

@property (nonatomic, strong) NSMutableDictionary *localVaribles;
@end

@implementation Clay_VMExecutor

+ (instancetype)shared{
    static Clay_VMExecutor *__clay = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        __clay = [[Clay_VMExecutor alloc] init];
        
    });
    
    return __clay;
}

- (id)init{
    if (self = [super init]) {
        self._jsContext = [[JSContext alloc] init];
        self._jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception){
            NSLog(@"clay exception -- exception:%@",exception);
        };
        self.localVaribles = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)run:(NSString *)script{
    if (![NSThread mainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self run:script];
        });
        return;
    }
    
    
    Clay *clay = [[Clay alloc] init];
    clay.jsContextRef = self._jsContext;
    self._jsContext[@"clay"] = clay;
    
    NSString *mScript = [self _preprocessing:script];
    
    mScript = [NSString stringWithFormat:@"%@%@",[self injectedJS],mScript];
    
    [self._jsContext evaluateScript:mScript];
}

- (NSString *)injectedJS{
    
    return [NSString stringWithFormat:@"var %@ = {};\r\n"
            "var %@ = {};\r\n"
            "function __clay_isFunction(fn) {\r\n"
            "return Object.prototype.toString.call(fn)=== '[object Function]';\r\n"
            "}\r\n"
            "function clayClass(define,impl){\r\n"
            "var classname = define.split(\":\",1);\r\n"
            "%@[classname[0]] = impl;\r\n"
            "clay.class(define,impl);}\r\n"
            "function clayProtocol(define,impl){\r\n"
            "clay.protocol(define,impl);}\r\n",
            JS_VARIABLE_MAP,JS_METHOD_MAP,JS_METHOD_MAP];
}

- (NSString *)_preprocessing:(NSString *)script{
    NSString *ret = nil;
    
    NSString *removeComment = [self _removeComment:script];
    if (removeComment) ret = removeComment;
    
    [self _doVariableKeeper:ret?ret:script];
    
    NSString *doEscapeAt = [self _doEscapeAt:ret?ret:script];
    if (doEscapeAt) ret = doEscapeAt;
    
    NSString *doExpr = [self _doExpr:ret?ret:script];
    if (doExpr) ret = doExpr;
    
    NSString *doInclude = [self _doInclude:ret?ret:script includeHistory:nil];
    if (doInclude) ret = doInclude;
    
    NSString *doUnescapeAt = [self _doUnescapeAt:ret?ret:script];
    if (doUnescapeAt) ret = doUnescapeAt;
    
    return ret;
}

- (NSString *)_removeComment:(NSString *)script{
    NSString *process = [script copy];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"((?<!:)\\/\\/.*|\\/\\*(\\s|.)*?\\*\\/)" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    
    process = [regex stringByReplacingMatchesInString:process
                                              options:0
                                                range:NSMakeRange(0, process.length)
                                         withTemplate:@""];
    
    process = [process stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return process;
}

static inline NSString *_getArgsDictionary(NSString *expr){

    NSMutableString *r = [[NSMutableString alloc] init];
    NSMutableString *cap = [[NSMutableString alloc] init];
    NSString *exprReplace = [expr copy];
    int i = 0;
    int maxJump = 5000;
    while (i < exprReplace.length || i > maxJump) {
        char c = [exprReplace characterAtIndex:i];
        
        if (c == '.'|| c == ',' || c == ')' || c == ';' || c == '='
            || c == '+' || c == '-' || c == '*' || c == '/' || c == '%'
            || c == '&' || c == '|'
            || c == '>' || c == '<') {
            NSInteger index = i - cap.length-1; ///look back one character
            
            if (index > 0 && [exprReplace characterAtIndex:index] == '.' ) { cap = [[NSMutableString alloc] init]; continue; }
            
            NSString *trimedCap = [cap stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceCharacterSet]];
            if (nil != [Clay_VMExecutor shared].localVaribles[trimedCap]) {
                
                if (![r isEqualToString:@""]) {
                    [r cat:@","];
                }
                
                [r cat:[NSString stringWithFormat:@"\"%@\":%@",
                            trimedCap,
                            _variableFunctionCheck(trimedCap)]];
            }
            cap = [[NSMutableString alloc] init];
        }
        else if (c == '(' || c == ':' || c == '-' ){
            cap = [[NSMutableString alloc] init];
        }
        else{
            [cap catC:c];
        }
        i++;
    }
    
    return [NSString stringWithFormat:@"{%@}",r];
}

- (NSString *)_doEscapeAt:(NSString *)script{
    __block NSString *process = [script copy];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"\"([\\w|\\s|%|:|~| |'|,|@|\\\\|.]+)\""
                                                                      options:0
                                                                        error:nil];
    NSInteger len = [process length];
    if (regex) {
        [regex enumerateMatchesInString:process
                                options:0
                                  range:NSMakeRange(0, len)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange range = [result rangeAtIndex:1];
                                 
                                 process = [[process stringByReplacingOccurrencesOfString:@"@"
                                             ///TODO:如换成不等长度字符串需要注意Range，Range在原字符串基础上
                                                                              withString:@"å"
                                                                                  options:0
                                                                                    range:range] copy];
                                 
                             }];
    }
    
    
    return process;
}

- (NSString *)_doUnescapeAt:(NSString *)script{
    NSString *process = [script copy];
    
    process = [process stringByReplacingOccurrencesOfString:@"å"
                                                 withString:@"@"];
    return process;
}


- (NSString *)_doExpr:(NSString *)script{
    
    __block  NSString *process = [script copy];
    
    
    //@([\\w|\\(|\\)|.|\"|$|\\[|\\]|:|,| |\\{|\\}|;|#|=|/|%| |~|'|\\\\]+)
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"@(.+)"
                                                                      options:0
                                                                        error:nil];
    
    
    
    NSInteger len = [process length];
    if (regex) {
        [regex enumerateMatchesInString:process
                                options:0
                                  range:NSMakeRange(0, len)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange range = [result rangeAtIndex:1];
                                 
                                 NSString *expr = [script substringWithRange:range];
                                 
                                 __stack * bracketStack;
                                 char c;
                                 for (int i = 0; i < expr.length; i++) {
                                     c = [expr characterAtIndex:i];
                                     if (c == '=') {
                                         NSInteger location = [expr rFind:@";"];
                                         if (location != NSNotFound) {
                                             expr = [expr substringToIndex:location + 1];
                                             break;
                                         }
                                     } else if (c == '(') {
                                         if (!bracketStack) {
                                             bracketStack = [[__stack alloc] init];
                                         }
                                         [bracketStack push:@""];
                                     } else if (c == ')') {
                                         if (bracketStack && ![bracketStack isEmpty]) {
                                             [bracketStack pop];
                                         } else {
                                             expr = [expr substringToIndex:i];
                                             break;
                                         }
                                     }
                                 }
                                 
                                 NSInteger exprLocation = [process find:[NSString stringWithFormat:@"@%@",expr]];
                                 
                                 NSString *argsDict = _getArgsDictionary(expr);
                                 
                                 NSString *clayExpr = [NSString stringWithFormat:@"clay.expr('%@',%@)%@",
                                                      expr,
                                                      argsDict,[expr hasSuffix:@";"]?@";":([expr hasSuffix:@","]?@",":@"")];
                                 
                                 process = [process stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"@%@",expr]
                                                                              withString:clayExpr
                                                                                 options:0
                                                                                   range:NSMakeRange(exprLocation, expr.length+1)];
                             }];
    }
    
    
    
    return process;
}


static inline NSString *_getFunctionVariableWithoutArgMarking(){
    NSString *v = [NSString stringWithFormat:@"__clay_tmp_func%ld_a",(long)TMP_V_INCREASE];
    TMP_V_INCREASE++;
    return v;
}


- (NSString *)_focusRemoveSemicolon:(NSString *)input{
    NSString *ret = [input copy];
    if ([ret hasSuffix:@";"]) {
        ret = [ret substringToIndex:ret.length-1];
    }
    
    return ret;
}

- (void)_doVariableKeeper:(NSString *)script{
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"var ([^;]+);{1}"
                                                                      options:0
                                                                        error:nil];
    
    __weak Clay_VMExecutor *weakSelf = self;
    
    if (regex) {
        
        
        [regex enumerateMatchesInString:script
                                options:0
                                  range:NSMakeRange(0, [script length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange range = [result rangeAtIndex:1];
                                 
                                 NSString *variables = [script substringWithRange:range];
                                 
                                 __stack * matchStack;
                                 char c;
                                 int lastPos = 0;
                                 int i = 0;
                                 for (; i < variables.length; i++) {
                                     c = [variables characterAtIndex:i];
                                     if (c == '=') {
                                         if (!matchStack) {
                                             matchStack = [[__stack alloc] init];
                                         }
                                         if ([matchStack isEmpty] || ![[matchStack top] isEqual:@"\""]) {
                                             [weakSelf.localVaribles setObject:@(1)
                                                                        forKey:[[variables substringWithRange:NSMakeRange(
                                                                                                                lastPos,i-lastPos)]
                                                                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                                             [matchStack push:@"="];
                                         }
                                     } else if (c == '(') {
                                         if (!matchStack) {
                                             matchStack = [[__stack alloc] init];
                                         }
                                         if ([matchStack isEmpty] || ![[matchStack top] isEqual:@"\""]) {
                                             [matchStack push:@"("];
                                         }
                                     } else if (c == ')') {
                                         if (matchStack && ![matchStack isEmpty] && [[matchStack top] isEqual:@"("]) {
                                             [matchStack pop];
                                         }
                                     } else if (c == '"') {
                                         if (i > 0 && [variables characterAtIndex:i - 1] != '\\') {
                                             if (!matchStack) {
                                                 matchStack = [[__stack alloc] init];
                                             }
                                             if ([matchStack isEmpty] || ![[matchStack top] isEqual:@"\""]) {
                                                 [matchStack push:@"\""];
                                             } else {
                                                 [matchStack pop];
                                             }
                                         }
                                     } else if (c == ',') {
                                         if (!matchStack || [matchStack isEmpty]) {
                                             [weakSelf.localVaribles setObject:@(1)
                                                                        forKey:[[variables substringWithRange:NSMakeRange(
                                                                                                            lastPos,i-lastPos)]
                                                                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                                             lastPos = i + 1;
                                         } else {
                                             if ([[matchStack top] isEqual:@"="]) {
                                                 [matchStack pop];
                                                 lastPos = i + 1;
                                             }
                                         }
                                     }
                                 }
                                 
                                 if (lastPos < i && (!matchStack || [matchStack isEmpty] || ![[matchStack top] isEqual:@"="])) {
                                     [weakSelf.localVaribles setObject:@(1)
                                                                forKey:[[variables substringWithRange:NSMakeRange(
                                                                                                        lastPos,i - lastPos)]
                                                                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                                 }

                             }];
    }
    
    
    regex = [[NSRegularExpression alloc] initWithPattern:@"function[ ]+[\\w]+[ ]*\\(([\\w|,|\\s]+)\\)"
                                                 options:0
                                                   error:nil];
    
    
    if (regex) {
        [regex enumerateMatchesInString:script
                                options:0
                                  range:NSMakeRange(0, [script length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange range = [result rangeAtIndex:1];
                                 
                                 NSString *variables = [script substringWithRange:range];
                                 
                                 NSArray *variablesSplict = [variables split:@","];
                                 
                                 for (NSString *variable in variablesSplict) {
                                     [weakSelf.localVaribles setObject:@(1)
                                                                forKey:variable];
                                 }
                                 
                                 
                             }];
    }
    
    regex = [[NSRegularExpression alloc] initWithPattern:@"\\w+:function\\(([\\w|,|\\s]+)\\)"
                                                 options:0
                                                   error:nil];
    
    if (regex) {
        [regex enumerateMatchesInString:script
                                options:0
                                  range:NSMakeRange(0, [script length])
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange range = [result rangeAtIndex:1];
                                 
                                 NSString *variables = [script substringWithRange:range];
                                 
                                 NSArray *variablesSplict = [variables split:@","];
                                 
                                 for (NSString *variable in variablesSplict) {
                                     [weakSelf.localVaribles setObject:@(1)
                                                                forKey:[variable
                                                                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                                 }
                                 
                                 
                             }];
    }
}



#define ClayScriptByPath(fileName) \
[NSString stringWithContentsOfFile:[self.scriptLoadPath stringByAppendingPathComponent:fileName]\
encoding:NSUTF8StringEncoding error:nil];

- (NSString *)_doInclude:(NSString *)script includeHistory:(NSMutableDictionary *)history{
    ///clay.require 添加原生JS
    ///clay.import 添加带Native的JS
    NSString *r = [script copy];
    
    NSInteger lB = NSNotFound;
    
    if (nil == history) {
        history = [[NSMutableDictionary alloc] init];
    }
    
    do{
        lB = [r find:CLAY_REQUIRE_BEGIN];
        NSInteger includeBeginOccupy = CLAY_REQUIRE_BEGIN.length;
        
        if (NSNotFound == lB){
            lB = [r find:CLAY_IMPORT_BEGIN];
            if (NSNotFound == lB) break;
            includeBeginOccupy = CLAY_IMPORT_BEGIN.length;
        }
        
        NSInteger lE = [r find:CLAY_INCLUDE_END
                       inRange:NSMakeRange(lB, r.length-lB)];
        
        if (lE == NSNotFound) break;
        
        NSString *fileName = [r substringWithRange:
                              NSMakeRange(lB+includeBeginOccupy,
                                          lE-lB-includeBeginOccupy)];
        
        if (history[fileName]) break;
        
        history[fileName] = @(1);
        
        NSString *includeJS = ClayScriptByPath(fileName);
        
        if (nil == includeJS){
            @throw  [NSException exceptionWithName:[NSString stringWithFormat:@"错误：%d",e_canNotFindIncludeFile]
                                            reason:[NSString stringWithFormat:@"找不到JS文件：%@",fileName]
                                          userInfo:nil];
        }
        
        
        
        
        if (CLAY_IMPORT_BEGIN.length == includeBeginOccupy) {
            [self _doVariableKeeper:includeJS];
            includeJS = [self _doEscapeAt:includeJS];
            includeJS = [self _doExpr:includeJS];
        }
        
        includeJS = [self _doInclude:includeJS includeHistory:history];
        
        
        r = [r stringByReplacingOccurrencesOfString:[r substringWithRange:NSMakeRange(lB,lE-lB+CLAY_INCLUDE_END.length)]
                                         withString:includeJS];
        
    }while (lB != NSNotFound);
    
    return r;
}

static inline NSString * _variableFunctionCheck(NSString *variable){
    NSString *funcVariable = [NSString  stringWithFormat:@"(\"%@\"+%@.length)",
                              _getFunctionVariableWithoutArgMarking(),variable];
    return [NSString stringWithFormat:
            @"("
            "__clay_isFunction(%@)"
            "?"
            "(%@[%@]=%@,%@)"
            ":"
            "%@"
            ")",
            variable,
            JS_METHOD_MAP,funcVariable,variable,funcVariable,
            variable
            ];
}


@end
