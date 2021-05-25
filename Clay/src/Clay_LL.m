//
//  Clay_LL.m
//  Clay
//
//  Created by yin shen on 10/2/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay_LL.h"

#import <objc/runtime.h>

#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Help.h>
#import <Clay/Clay_Define.h>
#import <Clay/Clay_Struct.h>
#import <Clay/Clay_LL+Expr.h>
#import <Clay/Clay_VMExecutor.h>

@interface Accessor : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, assign) NSInteger /*0 assign 1 retain 2 copy*/refer;
@property (nonatomic, assign) uintptr_t association;
@property (nonatomic, assign) BOOL nonatomic;
@property (nonatomic, assign) BOOL readonly;
@property (nonatomic, strong) NSString *getter;
@property (nonatomic, strong) NSString *setter;
@end

@implementation Accessor
@end

extern const NSString *JS_METHOD_MAP;


@interface Clay_LL()

@property (nonatomic, strong) __stack *invStack;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDictionary *defaultInit;
@property (nonatomic, strong) NSArray *operator;
@end





static NSString *clay_default_init =
@"NSString-initWithString:__NSCFString,"\
@"NSDictionary-initWithDictionary:__NSDictionaryI";

@interface Clay_LL()

@end

@implementation Clay_LL

- (id)init{
    if (self = [super init]){
        self.gramStack = [[__stack alloc] init];
        self.operatorStack = [[__stack alloc] init];
        self.tempGrammaStack = [[__stack alloc] init];
        self.tempGrammaStack.flag = 1;
        self.gramma4OperatorStack = [[__stack alloc] init];
        
    }
    return self;
}


- (NSDictionary *)defaultInit{
    if (!_defaultInit) {
        NSMutableDictionary *temp = [NSMutableDictionary dictionary];
        NSArray *splitComma = [clay_default_init split:@","];
        for (NSString *initPair in splitComma) {
            NSArray *splitDash = [initPair split:@"-"];
            
            NSArray *initMethods = [splitDash[1] split:@"|"];
            
            [temp setObject:initMethods
                     forKey:splitDash[0]];
        }
        
        _defaultInit = [temp copy];
    }
    
    return _defaultInit;
}



- (__stack *)invStack{
    if (!_invStack) _invStack = [[__stack alloc] init];
    return _invStack;
}


- (id)_parsing:(NSURL *)uri{
    [self _uriConvert:uri pushToStack:self.invStack];
#if Clay_DEBUG_MODE
    [self.invStack print];
#endif
    return  [self _excuteInvStack];
}



- (void)_uriConvert:(NSURL *)uri pushToStack:(__stack *)stack{
    
    
    NSArray *comp = [[NSString stringWithFormat:@"%@%@",
                      [[uri query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[[uri fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]?[[uri fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]:@""]
                     componentsSeparatedByString:@"_&_"];
    
    for (NSInteger i = comp.count-1; i >= 0; --i){
        
        NSString *stat = comp[i];
        if ([stat hasPrefix:@"expr["]) {
            stat = [stat stringByReplacingOccurrencesOfString:@"expr["
                                                   withString:@""];
            
            id r = nil;
            ///考虑支持多个分号隔开语句
            if ([stat hasSuffix:@";"]){
                stat = [stat substringToIndex:stat.length-1];
            }
            
            if ([stat hasSuffix:@","]){
                stat = [stat substringToIndex:stat.length-1];
            }
        
            r = [self evaluateStatement:stat];
            
            if (r) {
                [stack push:r];
            }
        }
        else{
            [stack push:stat];
        }
    }
    
    [stack push:[[uri host] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (id)_excuteInvStack{
    NSString *command = [self.invStack pop];
    
    if ([command isEqualToString:__EXPR__]) {
        return [self.invStack pop];
    }
    else if ([command isEqualToString:__CLASS__]){
        NSString *classDefine = [self.invStack pop];
        Class cls = __class(classDefine);
        __impl(__convert2Obj([self.invStack pop]), cls);
    }
    else if ([command isEqualToString:__PROTOCOL__]){
        NSString *protocolDefine = [self.invStack pop];
        Protocol *newP = __protocol(protocolDefine);
        __declare(__convert2Obj([self.invStack pop]), newP);
    }
    else if ([command isEqualToString:__SUPER__]){
        id obj = __convert2Obj([self.invStack pop]);
        Clay_Super *s = [[Clay_Super alloc] init];
        s.instance = obj;
        s.superClass = [obj superclass];
        return s;
    }
    
    return nil;
}

static inline Class __class(NSString *classDefine){
    NSScanner *scanner = [[NSScanner alloc] initWithString:classDefine];
    
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    if ([scanner scanUpToString:@":" intoString:&className]) {
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@"<" intoString:&superClassName];
            if (!scanner.isAtEnd) {
                scanner.scanLocation = scanner.scanLocation + 1;
                [scanner scanUpToString:@">" intoString:&protocolNames];
            }
        }
    }
    
    className = [className trim];
    superClassName = [superClassName trim];
    
    if (!superClassName) superClassName = @"NSObject";
    
    Class superClass = NSClassFromString(superClassName);
    if (!superClass) {
        @throw [NSException exceptionWithName:@"clay"
                                       reason:[NSString stringWithFormat:@"can not find supper class %@",superClassName]
                                     userInfo:nil];
    }
    
    
    Class class = NSClassFromString(className);
    
    if (!class) { //do not exist create new class
        class = objc_allocateClassPair(superClass, [className UTF8String], 0);
        objc_registerClassPair(class);
    }
    
    if (protocolNames.length) {
        NSArray *protocols = [protocolNames componentsSeparatedByString:@","];
        
        for (int i = 0; i < protocols.count; ++i) {
            Protocol *pI = objc_getProtocol([[protocols[i] trim] UTF8String]);
            if (pI) {
                class_addProtocol(class, pI);
            }
        }
    }
    
    return class;
}


static inline void __impl(NSDictionary *impls, Class cls){
    NSArray *keys = [impls allKeys];
    
    NSDictionary *pDict;
    for (NSString /* function name */ *key in keys) {
        if ([key isEqualToString:@"property"]) {
            pDict = impls[key];
        }
        else{ //functions
            NSString *functionName = key;
            
            SEL possibleSelectors[2];
            selectorsForName([functionName UTF8String],possibleSelectors);
            
            char *typeDescription = nil;
            for (int i = 0; i < 2; i++) {
                SEL selector = possibleSelectors[i];
                if (!selector) continue; // There may be only one acceptable selector sent back
                
                int argCount = 0;
                char *match = (char *)sel_getName(selector);
                while ((match = strchr(match, ':'))) {
                    match += 1; // Skip past the matched char
                    argCount++;
                }
                
                size_t typeDescriptionSize = 3 + argCount;
                typeDescription = calloc(typeDescriptionSize + 1, sizeof(char));
                memset(typeDescription, '@', typeDescriptionSize);
                typeDescription[2] = ':'; // Never forget _cmd!
                
                Method method = class_getInstanceMethod(cls, possibleSelectors[i]);
                if (NULL == method) {
                    method =class_getClassMethod(cls, possibleSelectors[i]);
                }
                
                if (NULL == method) { //add method
                    id metaclass = objc_getMetaClass(object_getClassName(cls));
#if __Clay_IS_ARM64__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    IMP noneIMP = class_getMethodImplementation(cls, @selector(__ClayNoneImplementSelector));
#pragma clang diagnostic pop
                    class_addMethod(cls, possibleSelectors[i], noneIMP, typeDescription) &&
                    class_addMethod(metaclass, possibleSelectors[i], noneIMP, typeDescription);
#else
                    class_addMethod(cls, possibleSelectors[i], (IMP)__Call_JS_IMP, typeDescription) &&
                    class_addMethod(metaclass, possibleSelectors[i], (IMP)__Call_JS_IMP, typeDescription);
#endif

                }
                else{   //override method
#if __Clay_IS_ARM64__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    IMP noneIMP = class_getMethodImplementation(cls, @selector(__ClayNoneImplementSelector));
#pragma clang diagnostic pop
                    if(!class_addMethod(cls, possibleSelectors[i], noneIMP, method_getTypeEncoding(method))){
                        method_setImplementation(method, noneIMP);
                    }
#else
                    if(!class_addMethod(cls, possibleSelectors[i], (IMP)__Call_JS_IMP, method_getTypeEncoding(method))){
                        method_setImplementation(method, (IMP)__Call_JS_IMP);
                    }
#endif
                }
                free(typeDescription);
            }
        }
    }
    
    if (pDict) {
        NSArray *propertyNames = [pDict allKeys];
        
        for (NSString *propertyName in propertyNames) {
            NSDictionary *followDetail = pDict[propertyName];
            
            NSString *t = followDetail.allKeys[0];
            
            if (t) {
                char *simpleTypeDescription = "";
                size_t size = 0;
                if ( __isClass(t)
                    || strcmp("", strcpy(simpleTypeDescription, __convert2SimpleTypeDescription(t,&size)))){
                    const char *ivarName = [[NSString stringWithFormat:@"_%@",propertyName] UTF8String];
                    
                    if (0 == strcmp(simpleTypeDescription, "")) {
                        class_addIvar(cls, ivarName, sizeof(id), log2(sizeof(id)), @encode(id));
                    }
                    else{
                        class_addIvar(cls, ivarName, size, log2(size), simpleTypeDescription);
                    }
                    
                    NSArray *desc = followDetail.allValues[0];
                    
                    objc_property_attribute_t type = { "T", .value = [[NSString stringWithFormat:@"@\"%@\"",t] UTF8String] };
                    objc_property_attribute_t backingivar = {"V", .value = ivarName};
                    objc_property_attribute_t attrs[5] = {0};
                    
                    attrs[0] = type;
                    attrs[1] = backingivar;
                    
                    #define _if_attribute(_o,str) \
                            if ([_o isEqualToString:(str)]){\
                                char name = [_o characterAtIndex:0] - 32;\
                                attrs[m+2].name = &name;\
                                attrs[m+2].value = " ";\
                            }
                    
                    for (int m = 0; m < desc.count; ++m) {
                        
                        NSString *o = desc[m];
                        if ([o isEqualToString:@"strong"]) {
                            attrs[m + 2].name = "&";
                            attrs[m + 2].value = " ";
                        }
                        else _if_attribute(o, @"copy")
                        else _if_attribute(o, @"nonatomic")
                        else _if_attribute(o, @"readonly")
                        else _if_attribute(o, @"weak")
                                        
                    }
                    
                    __accessor(cls, attrs, 5);
                    
                    BOOL suc = class_addProperty(cls, [propertyName UTF8String], attrs, 5);
                    if (suc) {}
                }
            }
        }
    }
    
#if __Clay_IS_ARM64__
    Method method = class_getInstanceMethod(cls, NSSelectorFromString(@"forwardInvocation:"));
    method_setImplementation(method, (IMP)__Call_JS_ForwardInvocation);
    method = class_getClassMethod(cls, NSSelectorFromString(@"forwardInvocation:")); 
    method_setImplementation(method, (IMP)__Call_JS_ForwardInvocation);
#endif
    class_addMethod(cls, @selector(setValue:forUndefinedKey:), (IMP)setValueForUndefinedKey, "v@:@@");
    class_addMethod(cls, @selector(valueForUndefinedKey:), (IMP)valueForUndefinedKey, "@@:@");
}

static inline char * __convert2SimpleTypeDescription(NSString *inputType, size_t *size){
    #define __case_normal_type(__t__)\
        if ([inputType isEqualToString:@#__t__]){\
            *size = sizeof(__t__);\
            return @encode(__t__);\
    }
    
    __case_normal_type(NSInteger)
    else __case_normal_type(int)
    else __case_normal_type(CGFloat)
    else __case_normal_type(float)
    else __case_normal_type(BOOL)
    else __case_normal_type(bool)
    else __case_normal_type(float)
    else __case_normal_type(double)
    return "";
}

static inline Protocol *__protocol(NSString *protocolDefine){
    NSScanner *scanner = [[NSScanner alloc] initWithString:protocolDefine];
    
    NSString *protocolName;
    NSString *superProtocolNames;
    if ([scanner scanUpToString:@"<" intoString:&protocolName]) {
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@">" intoString:&superProtocolNames];
        }
    }
    
    protocolName = [protocolName trim];
    superProtocolNames = [superProtocolNames trim];
    
    Protocol *p = objc_allocateProtocol([protocolName UTF8String]);
    
    NSArray *protocolInheritList = [superProtocolNames componentsSeparatedByString:@","];
    for(int i = 0; i < protocolInheritList.count; i++){
        Protocol *pI = objc_getProtocol([protocolInheritList[i] UTF8String]);
        if (pI) protocol_addProtocol(p,pI);
    }
    
    
    return p;
}

static inline void __declare(NSDictionary *declare, Protocol *protocol){
    NSArray *keys = [declare allKeys];
    
    for (NSString *functionDeclare in keys) {
        SEL possibleSelectors[2];
        selectorsForName([functionDeclare UTF8String],possibleSelectors);
        
        char *typeDescription = nil;
        for (int i = 0; i < 2; i++) {
            SEL selector = possibleSelectors[i];
            if (!selector) continue; // There may be only one acceptable selector sent back
            
            int argCount = 0;
            char *match = (char *)sel_getName(selector);
            while ((match = strchr(match, ':'))) {
                match += 1; // Skip past the matched char
                argCount++;
            }
            
            size_t typeDescriptionSize = 3 + argCount;
            typeDescription = calloc(typeDescriptionSize + 1, sizeof(char));
            memset(typeDescription, '@', typeDescriptionSize);
            typeDescription[2] = ':'; // Never forget _cmd!
            
            protocol_addMethodDescription(protocol, selector, typeDescription, YES, YES);
            
            free(typeDescription);
        }
    }
    
    objc_registerProtocol(protocol);
}

static inline void __accessor(Class cls, const objc_property_attribute_t *attributes, unsigned int attributeCount){
    Accessor *a = [[Accessor alloc] init];
    
    objc_property_attribute_t pn = attributes[1];
    NSString *pnStr = [NSString stringWithFormat:@"%s",pn.value];
    NSString *p = [pnStr substringFromIndex:1];
    
    
    NSString *pKey  = [NSString stringWithFormat:@"%@_%@",NSStringFromClass(cls),p];
    a.key = pKey;
    
    NSString *getter = p;
    NSString *setter = [NSString stringWithFormat:@"set%c%@:",[getter characterAtIndex:0]-32,[getter substringFromIndex:1]];
    
    Method getterM = class_getInstanceMethod(cls, NSSelectorFromString(getter));
    if (getterM) { a.getter = getter; }
    
    Method setterM = class_getInstanceMethod(cls, NSSelectorFromString(setter));
    if (setterM) { a.setter = setter; }
    
    for (int i = 2; i < attributeCount; ++i){
        objc_property_attribute_t attr = attributes[i];
        if (attr.name && 0 == strcasecmp(attr.name, "&")) {
            a.refer = 1;
        }
        else if (attr.name && 0 == strcasecmp(attr.name, "C")){
            a.refer = 2;
        }
        else if (attr.name && 0 == strcasecmp(attr.name, "R")){
            a.readonly = YES;
        }
        else if (attr.name && 0 == strcasecmp(attr.name, "N")){
            a.nonatomic = YES;
        }
    }
    
    if (a.refer == 1) {
        a.association = a.nonatomic?OBJC_ASSOCIATION_RETAIN_NONATOMIC:OBJC_ASSOCIATION_RETAIN;
    }
    else if (a.refer == 2){
        a.association = a.nonatomic?OBJC_ASSOCIATION_COPY_NONATOMIC:OBJC_ASSOCIATION_COPY;
    }

    [[__clay_prefix(R) getPropertyKeyPointers] setObject:a forKey:pKey];
}


///copy from wax
void selectorsForName(const char *methodName, SEL possibleSelectors[2]) {
    NSInteger strlength = strlen(methodName) + 2; // Add 2. One for trailing : and one for \0
    char *objcMethodName = calloc(strlength, 1);
    
    int argCount = 0;
    strcpy(objcMethodName, methodName);
    for(int i = 0; objcMethodName[i]; i++) {
        if (objcMethodName[i] == '_') {
            argCount++;
            objcMethodName[i] = ':';
        }
    }
    
    objcMethodName[strlength - 2] = ':'; // Add final arg portion
    possibleSelectors[0] = sel_getUid(objcMethodName);
    
    if (argCount == 0) {
        objcMethodName[strlength - 2] = '\0';
        possibleSelectors[1] = sel_getUid(objcMethodName);
    }
    else {
        possibleSelectors[1] = nil;
    }
    free(objcMethodName);
}

#if !__Clay_IS_ARM64__
static id  __Call_JS_IMP(id self, SEL cmd,...){
    
    NSString *classKey = NSStringFromClass([self class]);
    NSString *funcName = NSStringFromSelector(cmd);
    
    NSMethodSignature *signature = [(NSObject *)self methodSignatureForSelector:cmd];
    
    funcName = [funcName stringByReplacingOccurrencesOfString:@":"
                                                   withString:@"_"];
    
    if ([funcName characterAtIndex:funcName.length-1]=='_') {
        funcName = [funcName substringToIndex:funcName.length-1];
    }
    
    NSInteger argsCount = [signature numberOfArguments];
    
    NSString *func = [NSString stringWithFormat:@"%@['%@'].%@",JS_METHOD_MAP,classKey,funcName];
    
    JSValue *method = [[Clay_VMExecutor shared]._jsContext evaluateScript:func];
    
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    
    if (!object_isClass(self)) {
        [args addObject:self];
    }
    
    
    if (argsCount == 2) {
        if (args.count == 0) args = nil;
    }
    else{
        va_list arg_ptr;
        va_start(arg_ptr, cmd);
        id arg;
        NSInteger argsAdded = 0;
        
        while(argsAdded++ < argsCount && (arg = va_arg(arg_ptr,id)) ){
            [args addObject:arg];
        }
        va_end(arg_ptr);
    }
    
    JSValue *v = [method callWithArguments:args];
    
    const char * typeDescription = [signature methodReturnType];
    switch (typeDescription[0]) {
        default:{
            return [v toObject];
        }
    }
    
}
#endif

#if __Clay_IS_ARM64__
static void __Call_JS_ForwardInvocation(id fISelf,SEL fICmd, NSInvocation *anInvocation){
    NSMethodSignature *signature = [anInvocation methodSignature];

    SEL cmd;
    [anInvocation getArgument:&cmd atIndex:1];
    
    NSString *classKey = NSStringFromClass([fISelf class]);
    NSString *funcName = NSStringFromSelector(cmd);
    
    funcName = [funcName stringByReplacingOccurrencesOfString:@":"
                                                   withString:@"_"];
    
    if ([funcName characterAtIndex:funcName.length-1]=='_') {
        funcName = [funcName substringToIndex:funcName.length-1];
    }

    NSString *func = [NSString stringWithFormat:@"%@['%@'].%@",JS_METHOD_MAP,classKey,funcName];
    
    JSValue *method = [[Clay_VMExecutor shared]._jsContext evaluateScript:func];
    
    
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    
    if (!object_isClass(fISelf)) {
        [args addObject:fISelf];
    }
    
    
    
    for (int i = 2; i < [signature numberOfArguments]; ++i) {
        __unsafe_unretained id arg;
        [anInvocation getArgument:&arg atIndex:i];
        [args addObject:arg];
    }
    
    
    
    JSValue *v = [method callWithArguments:args];
    id o = [v toObject];
    if (o) {
        [anInvocation setReturnValue:&o];
    }
}
#endif

static void setValueForUndefinedKey(id self, SEL cmd, id value, NSString *key){
    
    if ([key isEqualToString:@"groupModel"]){
        NSLog(@"");
    }
    
    Accessor *accessor = [[__clay_prefix(R) getPropertyKeyPointers] objectForKey:
                          [NSString stringWithFormat:@"%@_%@",NSStringFromClass([self class]),key]];
    
    if (nil == accessor) return;
    
    id setterObj;
    if (accessor.setter.length){
        setterObj = [Clay_LL _callClassSetProperty:key sender:self value:value];
    }
    
    if (nil == setterObj) { setterObj = value; }
    objc_setAssociatedObject(self, (__bridge const void *)(accessor.key), setterObj, accessor.association);
}




static id valueForUndefinedKey(id self, SEL cmd, NSString *key){
    Accessor *accessor = [[__clay_prefix(R) getPropertyKeyPointers] objectForKey:
                          [NSString stringWithFormat:@"%@_%@",NSStringFromClass([self class]),key]];
    
    if (nil == accessor) return nil;
    
    id getterObj = objc_getAssociatedObject(self, (__bridge const void *)(accessor.key));
    if (getterObj) { return getterObj; }
    
    if (accessor.getter) {
        getterObj = [Clay_LL _callClassGetProperty:key sender:self];
        if (getterObj) {
            objc_setAssociatedObject(self, (__bridge const void *)(accessor.key), getterObj,accessor.association);
            return getterObj;
        }
    }
    
    return nil;
}

- (void)_callClassDefineJSFunction:(NSString *)funcName sender:(id)sender args:(NSArray *)arg{
    [self.jsContextRef evaluateScript:@"%@[%@]"];
}

+ (id)_callClassGetProperty:(NSString *)propertyName sender:(id)sender{
    NSString *classKey = NSStringFromClass([sender class]);
    NSString *func = [NSString stringWithFormat:@"%@['%@'].%@.get",JS_METHOD_MAP,classKey,propertyName];
    JSValue *get = [[Clay_VMExecutor shared]._jsContext evaluateScript:func];
    if (nil == [get toObject]) {
        return nil;
    }
    return [[get callWithArguments:[NSArray arrayWithObjects:sender, nil]] toObject];
}

+ (id)_callClassSetProperty:(NSString *)propertyName sender:(id)sender value:(id)vaule{
    NSString *classKey = NSStringFromClass([sender class]);
    NSString *func = [NSString stringWithFormat:@"%@['%@'].%@.set",JS_METHOD_MAP,classKey,propertyName];
    JSValue *set = [[Clay_VMExecutor shared]._jsContext evaluateScript:func];
    if (nil == [set toObject]) {
        return nil;
    }
    return [[set callWithArguments:[NSArray arrayWithObjects:sender,vaule,nil]] toObject];
}

static inline id __convert2Obj(NSString *input){
    if ([input hasPrefix:@"@("]) {
        return [__clay_prefix(R) o:[[input substringWithRange:NSMakeRange(2, input.length-3)] integerValue]];
    }
    else{
        @throw [NSException exceptionWithName:@"clay"
                                       reason:[NSString stringWithFormat:@"can not convert to object %@",input]
                                     userInfo:nil];
    }
}

static inline BOOL __isClass(NSString *s){ return NSClassFromString(s); }


@end
