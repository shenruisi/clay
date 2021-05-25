//
//  Clay_VM+Executor.m
//  Clay
//
//  Created by ris on 7/28/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_VM+Executor.h"
#import <Clay/Clay_CLObjects.h>
#import <objc/runtime.h>
#import <Clay/Clay_Help.h>
#import <Clay/Clay_Kenel.h>

#import <CoreGraphics/CoreGraphics.h>
@implementation Clay_VM (Executor)

void run(Clay_VM *this,CLClass *classObj){
    if (classObj){
        /* register class if needed */
        Class class = NSClassFromString(classObj.class);
        Class superClass = NSClassFromString(classObj.superClass);
        
        if (!class) {
            class = objc_allocateClassPair(superClass, [classObj.class UTF8String], 0);
            objc_registerClassPair(class);
        }
        
        /* register protocols if needed */
        for (NSString *protocol in classObj.protocols) {
            Protocol *pI = objc_getProtocol([protocol UTF8String]);
            if (pI) {
                class_addProtocol(class, pI);
            }
        }
        
        /* register ivars if needed */
        for (CLIVar *ivar in [classObj.ivars objectEnumerator]) {
            class_addIvar(class,
                          [ivar.name UTF8String],
                          ivar.sizeType,
                          0,
                          [ivar.typeEncoding UTF8String]);
        }
        
        /* register properties if needed */
        for (CLProperty *property in [classObj.properties objectEnumerator]){
            char *simpleTypeDescription = "";
            size_t size = 0;
            
            if (strcmp("", strcpy(simpleTypeDescription, __convert2SimpleTypeDescription(property.T,&size)))){
                const char *ivarName = [[NSString stringWithFormat:@"_%@",property.V] UTF8String];
                
                if (0 == strcmp(simpleTypeDescription, "")) {
                    class_addIvar(class, ivarName, sizeof(id), log2(sizeof(id)), @encode(id));
                }
                else{
                    class_addIvar(class, ivarName, size, log2(size), simpleTypeDescription);
                }
                
                objc_property_attribute_t type = { "T", .value = [[NSString stringWithFormat:@"@\"%@\"",property.T] UTF8String] };
                objc_property_attribute_t backingivar = {"V", .value = ivarName};
                objc_property_attribute_t attrs[5] = {0};
                
                attrs[0] = type;
                attrs[1] = backingivar;
            
                for (int i = 0; i < property.attrs.count; ++i) {
                    const char attr_name = [property.attrs[i] characterAtIndex:0];
                    attrs[2+i].name = &attr_name;
                    attrs[2+i].value = " ";
                }
                
                BOOL suc = class_addProperty(class, [property.V UTF8String], attrs, 5);
                if (suc) {}
            }
        }
        
        /* register methods if needed */
        for (CLIMP *imp in classObj.imps) {
            SEL selector = sel_getUid([imp.sel UTF8String]);
            if (!selector) continue;
            
            int argCount = 0;
            char *match = (char *)sel_getName(selector);
            while ((match = strchr(match, ':'))) {
                match += 1; // Skip past the matched char
                argCount++;
            }
            
            char *typeDescription = nil;
            size_t typeDescriptionSize = 3 + argCount;
            typeDescription = calloc(typeDescriptionSize + 1, sizeof(char));
            memset(typeDescription, '@', typeDescriptionSize);
            typeDescription[2] = ':'; // Never forget _cmd!
            
            Method method = class_getInstanceMethod(class, selector);
            if (NULL == method) {
                method =class_getClassMethod(class, selector);
            }
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            IMP noneIMP = class_getMethodImplementation(class, @selector(__ClayNoneImplementSelector));
#pragma clang diagnostic pop
            
            if (NULL == method) { //add method
                //id metaclass = objc_getMetaClass(object_getClassName(class));
                
                class_addMethod(class, selector, noneIMP, typeDescription);
                //class_addMethod(metaclass, possibleSelectors[i], noneIMP, typeDescription);
            }
            else { //override method
                if(!class_addMethod(class, selector, noneIMP, method_getTypeEncoding(method))){
                    method_setImplementation(method, noneIMP);
                }
            }
            
            free(typeDescription);
        }
        
        Method method = class_getInstanceMethod(class, NSSelectorFromString(@"forwardInvocation:"));
        method_setImplementation(method, (IMP)__CL_RT_ForwardInvocation);
    }
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

static void __CL_RT_ForwardInvocation(id fISelf,SEL fICmd, NSInvocation *anInvocation){
    CLIMPContext *impCxt = [Clay_VM getIMPContext:anInvocation];
    _recursiveBlockExcutor(impCxt.block, impCxt.context);
}

static void _recursiveBlockExcutor(CLBlock *block, CLContext *context){
    for (int i = 0; i < block.codes.count; ++i) {
        CLBlock *b = block.codes[i];
        switch (b.type) {
            case CLStat:
            {
                CLBlockStat *stat = (CLBlockStat *)b;
                [Clay_Kenel expr:stat.expr context:context];
            }
                break;
                
            default:
                break;
        }
    }
}

@end
