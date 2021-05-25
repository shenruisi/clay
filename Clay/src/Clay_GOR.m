//
//  Clay_GOR.m
//  Clay
//
//  Created by yin shen on 10/2/15.
//  Copyright (c) 2015 yin shen. All rights reserved.
//

#import "Clay_GOR.h"
#import <objc/runtime.h>

@implementation __clay_prefix(R)

static __clay_prefix(R) *_gor;
static NSInteger _gorIDAutoIncrease;
static NSMutableDictionary *_objectKeyPointers;
static NSMutableDictionary *_propertyKeyPointers;
static NSMutableDictionary *_gorIDs;

+ (void)initialize{
    if (self == [__clay_prefix(R) self]) {
        if (!_gor) { _gor = [[__clay_prefix(R) alloc] init]; }
        if (!_gorIDs) { _gorIDs = [[NSMutableDictionary alloc] init]; }
        if (!_objectKeyPointers) { _objectKeyPointers = [[NSMutableDictionary alloc] init]; }
        if (!_propertyKeyPointers) { _propertyKeyPointers = [[NSMutableDictionary alloc] init]; }
    }
}

+ (NSInteger)_getGORID{
    return (++_gorIDAutoIncrease);
}

+ (NSInteger)kWO:(id)object{
    return _setObjectWithPolicy(object, OBJC_ASSOCIATION_ASSIGN);
}

+ (NSInteger)kSO:(id)object{
    return _setObjectWithPolicy(object, OBJC_ASSOCIATION_RETAIN);
}

static inline NSInteger _setObjectWithPolicy(id object, unsigned long policy){
    if (!object) return Clay_GOR_NotFound;
    
    @synchronized(_gorIDs) {
        NSString *key;
        NSUInteger hash = [object hash];
        
        NSString *prefix = @"obj";
        if ([object isKindOfClass:[NSArray class]]
            ||[object isKindOfClass:[NSDictionary class]]) {
            hash = (NSInteger)object;
            prefix = @"base";
        }
        key = [NSString stringWithFormat:@"%@_%ld",prefix,hash];
        
        id exsitGorID;
        NSInteger newID = Clay_GOR_NotFound;
        if ((exsitGorID = _objectKeyPointers[key])) {
            newID = [exsitGorID integerValue];
        }
        else{
            newID = [__clay_prefix(R) _getGORID];
        }
        
        objc_setAssociatedObject(_gor, (__bridge const void *)(key), object, OBJC_ASSOCIATION_ASSIGN);
        _gorIDs[@(newID)] = key;
        _objectKeyPointers[key] = @(newID);
        
        return newID;
    }
}

+ (id)o:(NSInteger)gorID{
    if (gorID == Clay_GOR_NotFound) return nil;
    
    @synchronized(_gorIDs) {
        NSString *key = _gorIDs[@(gorID)];
        
        if (!key) return nil;
        
        return objc_getAssociatedObject(_gor, (__bridge const void *)(key));
    }
    
}

+ (NSMutableDictionary *)getPropertyKeyPointers{
    return _propertyKeyPointers;
}

+ (id)null{ return nil; }
+ (BOOL)no{ return NO; }
+ (BOOL)yes{ return YES; }

@end
