//
//  Clay_Object.h
//  Clay
//
//  Created by ris on 4/1/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>
#define Clay_Object @"Clay_Object_"

@interface Clay_Object_Dictionary : NSObject
@property (nonatomic, strong) NSMutableDictionary *value;
- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary;
- (void)removeObjectForKey:(NSString *)aKey;
- (void)setObject:(id)anObject forKey:(NSString *)aKey;
- (instancetype)initWithCapacity:(NSUInteger)numItems;

//NSExtendedMutableDictionary
- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;
- (void)removeAllObjects;
@end

@interface Clay_Object_Array : NSMutableArray
@property (nonatomic, strong) NSMutableArray *value;

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (instancetype)initWithCapacity:(NSUInteger)numItems;

- (instancetype)initWithArray:(NSArray *)array;

@property (readonly) NSUInteger count;
@end