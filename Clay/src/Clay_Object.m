//
//  Clay_Object.m
//  Clay
//
//  Created by ris on 4/1/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_Object.h"


@implementation Clay_Object_Dictionary

- (id)init{
    self = [super init];
    if (self) {
        self.value = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary{
    self = [super init];
    if (self) {
        
        if ([otherDictionary isKindOfClass:[Clay_Object_Dictionary class]]){
            self.value = [NSMutableDictionary dictionaryWithDictionary:
                          ((Clay_Object_Dictionary *)otherDictionary).value];
        }
        else{
            self.value = [NSMutableDictionary dictionaryWithDictionary:otherDictionary];
        }
        
    }
    
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems{
    self = [super init];
    if (self) {
        self.value = [NSMutableDictionary dictionaryWithCapacity:numItems];
    }
    
    return self;
}

- (void)removeObjectForKey:(NSString *)aKey{
    [self.value removeObjectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey{
    [self.value setObject:anObject forKey:aKey];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary{
    [self.value addEntriesFromDictionary:otherDictionary];
}

- (void)removeAllObjects{
    [self.value removeAllObjects];
}

- (NSString *)description{
    NSMutableString *s = [NSMutableString stringWithString:@"\nDictionary:\n{\n"];
    [self.value enumerateKeysAndObjectsUsingBlock:^(id key,id object,BOOL *stop){
        [s appendFormat:@"\t%@ : %@\n",key,object];
    }];
    
    [s appendFormat:@"}\n"];
    return s;
}

@end

@implementation Clay_Object_Array

- (NSUInteger)count{
    return self.value.count;
}

- (instancetype)init{
    if (self = [super init]) {
        self.value = [NSMutableArray array];
    }
    
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems{
    if (self = [super init]) {
        self.value = [NSMutableArray arrayWithCapacity:numItems];
    }
    
    return self;
}

- (instancetype)initWithArray:(NSArray *)array{
    if (self = [super init]) {
        if ([array isKindOfClass:[Clay_Object_Array class]]){
            self.value = [NSMutableArray arrayWithArray:
                          ((Clay_Object_Array *)array).value];
        }
        else{
            self.value = [NSMutableArray arrayWithArray:array];
        }
    }
    
    return self;
}

- (void)addObject:(id)anObject{
    [self.value addObject:anObject];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index{
    [self.value insertObject:anObject atIndex:index];
}

- (void)removeLastObject{
    [self.value removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index{
    [self.value removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject{
    [self.value replaceObjectAtIndex:index withObject:anObject];
}


- (NSString *)description{
    NSMutableString *s = [NSMutableString stringWithString:@"\nArray:\n[\n"];
    for (int i = 0; i < self.value.count; ++i) {
        [s appendFormat:@"\t%@\n",self.value[i]];

    }
    
    [s appendFormat:@"]\n"];
    return s;
}

@end
