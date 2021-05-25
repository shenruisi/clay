//
//  Clay_Tree.h
//  Clay
//
//  Created by ris on 5/9/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Clay/Clay_Help.h>

@interface CTNode : NSObject

@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *value2;
@property (atomic, strong) NSMutableDictionary *children;
@end

@interface Clay_Tree : NSObject

+ (CTNode *)setHead:(Grammar *)g;
+ (CTNode *)head:(NSString *)key;
+ (NSString *)calcKey:(Grammar *)g;
+ (void)append:(Grammar *)g to:(CTNode *)curNode;

+ (void)process:(CTNode *)startNode
       instance:(id)instance
           stat:(NSString *)stat
     startIndex:(NSInteger *)startIndex
         gArray:(NSMutableArray **)gArray;

+ (void)printHeads;
@end
