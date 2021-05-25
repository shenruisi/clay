//
//  Clay_Tree.m
//  Clay
//
//  Created by ris on 5/9/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_Tree.h"
#import <objc/runtime.h>
#import <Clay/Clay_GOR.h>
#import <Clay/Clay_Define.h>
#import <UIKit/UIKit.h>

extern void *__invoke(id sender,SEL cmd,NSMutableArray *args);

@implementation CTNode

- (id)init{
    if (self = [super init]) {
        self.children = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSString *)description{
    
    NSMutableString *children = [[NSMutableString alloc] init];
    NSArray *keys = self.children.allKeys;
    for (int i = 0; i < keys.count; ++i) {
        [children appendString:[self.children[keys[i]] description]];
        if (i != keys.count-1) {
            [children appendString:@","];
        }
    }
    
    return [NSString stringWithFormat:
            @"code = %@,value = %@,value2 = %@,range = %@,(children = %@),",
            self.code,
            self.value,
            self.value2,
            NSStringFromRange(self.range),
            children
            ];
}

@end

static NSMutableDictionary *_heads;
static NSDictionary *_ocOpacityClasses;
@implementation Clay_Tree

+ (void)initialize{
    if (self == [Clay_Tree self]) {
        if (!_heads) { _heads = [[NSMutableDictionary alloc] init]; }
        
        if (!_ocOpacityClasses){
            _ocOpacityClasses = @{
                                  @"UICachedDeviceRGBColor":@"UIColor"
                                  };
        }
    }

}

static inline NSString *__classesConvertor(NSString *class){
    return _ocOpacityClasses[class];
}

+ (CTNode *)head:(NSString *)key{
    return [_heads objectForKey:key];
}

+ (CTNode *)setHead:(Grammar *)g{
    if (!g || !g.data) { return nil; }
    
    if (__grammar_is_C(g) || __grammar_is_I(g)) {
        CTNode *node = [Clay_Tree _createNode:g];
        if (![_heads objectForKey:node.value] ) {
            [_heads setObject:node forKey:node.value];
            return node;
        }
    }
    return nil;
}

+ (void)append:(Grammar *)g to:(CTNode *)curNode{
    if (!curNode) { return; }
    
    CTNode *unsureNode = [Clay_Tree _createNode:g];
    //check if unsureNode is head node.
    CTNode *headNode = [Clay_Tree head:unsureNode.value];
    if (headNode) { unsureNode = headNode; }
    
    NSMutableDictionary *children = curNode.children;
    if (!children[unsureNode.value]) {
        [children setObject:unsureNode forKey:unsureNode.value];
    }
    
    curNode = children[unsureNode.value];
}


+ (void)process:(CTNode *)startNode
       instance:(id)instance
           stat:(NSString *)stat
     startIndex:(NSInteger *)startIndex
         gArray:(NSMutableArray **)gArray{
    NSMutableDictionary *children = startNode.children;
    
    if (*gArray == nil) { *gArray = [[NSMutableArray alloc] init]; }
    
    NSArray *keys = [children keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        return [((CTNode *)obj2).value length] > [((CTNode *)obj1).value length];
    }];
    
    BOOL findChild = false;
    
    for (int i = 0; i < keys.count; ++i) {
        CTNode *child = children[keys[i]];
        
        if (*startIndex+child.range.location+child.range.length > stat.length) {
            continue;
        }
        
        NSString *nextPhrase = [stat substringWithRange:
                                NSMakeRange(
                                            *startIndex+child.range.location,
                                            child.range.length
                                            )
                                ];
        
        
        if ([nextPhrase isEqualToString:child.value]) {
            *startIndex += child.range.location+child.range.length;
            
            if ([child.code isEqualToString:@"P"]) {
                
                NSString *p = [child.value substringFromIndex:1]; //jump .
                
                if ([instance isKindOfClass:[NSValue class]]) {
                    const char *objCType = ((NSValue *)instance).objCType;
                    
                    
                    if (0 == strcmp(objCType, @encode(CGRect))){
                        CGRect rect = [instance CGRectValue];
                        
                        if ([p isEqualToString:@"size"]) {
                            instance = [NSValue valueWithCGSize:rect.size];
                        }
                        else if ([p isEqualToString:@"origin"]){
                            instance = [NSValue valueWithCGPoint:rect.origin];
                        }
                    }
                    else if (0 == strcmp(objCType, @encode(CGSize))){
                        CGSize size = [instance CGSizeValue];
                        
                        if ([p isEqualToString:@"width"]) {
                            instance = [NSNumber numberWithFloat:size.width];
                        }
                        else if ([p isEqualToString:@"height"]){
                            instance = [NSNumber numberWithFloat:size.height];
                        }
                    }
                    else if (0 == strcmp(objCType, @encode(CGPoint))){
                        CGPoint point = [instance CGPointValue];
                        
                        if ([p isEqualToString:@"x"]) {
                            instance = [NSNumber numberWithFloat:point.x];
                        }
                        else if ([p isEqualToString:@"y"]){
                            instance = [NSNumber numberWithFloat:point.y];
                        }
                    }
                }
                else if ([instance isKindOfClass:[NSArray class]]){
                    if ([p isEqualToString:@"count"]){
                        instance = [NSNumber numberWithInteger:[((NSArray *)instance) count]];
                    }
                }
                else{
                    id r = [instance valueForKey:p];
                    
                    
                    
                    if (!r) {
                        Grammar *gP = [[Grammar alloc] init];
                        gP.code = @"I";
                        gP.data2 = instance;
                        gP.data3 = p;
                        instance = gP;
                    }
                    else{
                        instance = r;
                    }
                }
                
                
                if (instance) {
                    Grammar *g = [[Grammar alloc] init];
                    g.code = @"I";
                    g.data = instance;
                    [Clay_Tree setHead:g];
                }
                
                child = [Clay_Tree head:NSStringFromClass([instance class])];
            }
            else if ([child.code isEqualToString:@"IM"]){
                if ([child.value2 isEqualToString:__NO_PARAM__]) {
                    
                    *startIndex += 1;
                    
                    instance = (__bridge id)(__invoke(instance,
                                                      NSSelectorFromString([child.value substringWithRange:NSMakeRange(1, [child.value length]-2)]),
                                                      nil));
                    
                    if (instance) {
                        Grammar *g = [[Grammar alloc] init];
                        g.code = @"I";
                        g.data = instance;
                        [Clay_Tree setHead:g];
                    }
                    
                    child = [Clay_Tree head:NSStringFromClass([instance class])];
                }
                
                
            }
            else if ([child.code isEqualToString:@"SM"]){
                if ([child.value2 isEqualToString:__NO_PARAM__]) {
                    
                    *startIndex += 1;
                    
                    instance = (__bridge id)(__invoke(NSClassFromString(startNode.value),
                                                     NSSelectorFromString([child.value substringWithRange:NSMakeRange(1, [child.value length]-2)]),
                                                      nil));
                    
                    if (instance) {
                        Grammar *g = [[Grammar alloc] init];
                        g.code = @"I";
                        g.data = instance;
                        [Clay_Tree setHead:g];
                    }
                    
                    child = [Clay_Tree head:NSStringFromClass([instance class])];
                }
                else{
                    if ([startNode.value isEqualToString:__clay_prefix_str(R)] && [child.value isEqualToString:@".o("]) {
                        
                        NSInteger l = [stat find:@")" inRange:NSMakeRange(*startIndex, stat.length-*startIndex)];
                        instance = [__clay_prefix(R) o:[[stat substringWithRange:NSMakeRange(*startIndex, l-*startIndex)] integerValue]];
                        
                        *startIndex += l-*startIndex+1;
                        
                        if (instance) {
                            Grammar *g = [[Grammar alloc] init];
                            g.code = @"I";
                            g.data = instance;
                            [Clay_Tree setHead:g];
                        }
                        
                        child = [Clay_Tree head:NSStringFromClass([instance class])];
                    
                    }
                }
            }
            
            findChild = YES;
            
            [Clay_Tree process:child
                      instance:instance
                          stat:stat
                    startIndex:startIndex
                        gArray:gArray];
            break;
        }        
    }
    
    if (startNode) {
        Grammar *g = [Clay_Tree _createGrammar:startNode];
        if (instance && (__grammar_is_I(g) || __grammar_is_C(g)) ) {
            
            if ([*gArray count]) {
                Grammar *_unsureI = (*gArray)[(*gArray).count-1];
                if ([_unsureI.code isEqualToString:@"I"]) {  //递归调用 只需要保存最后的一个instance
                    return;
                }
            }
            
            if (!findChild) { *startIndex -= 1; }
            
            if ([instance isKindOfClass:[Grammar class]]) {
                [*gArray addObject:instance];
            }
            else{
                g.code = @"I";
                g.data = instance;
                [*gArray addObject:g];
            }
            
            
        }
        else if (__grammar_is_IM(g)
                 || __grammar_is_SM(g)
                 ){
            
            if (!findChild) { *startIndex -= 1; }
            
            Grammar *gB = [[Grammar alloc] init];
            gB.code = @"(";
            gB.data = @"(";
            gB.expr = @"(";
            gB.data2 = @(*startIndex);
            [*gArray addObject:gB];
            
            g.data = [g.data substringWithRange:NSMakeRange(1, [g.data length]-2)];
            
            [*gArray addObject:g];
            
            Grammar *gP = [[Grammar alloc] init];
            gP.code = @".";
            gP.data = @".";
            gP.expr = @".";
            [*gArray addObject:gP];
        }
        else{
            if (!findChild) { *startIndex -= 1; }
            [*gArray addObject:g];
        }
    }
}

+ (Grammar *)_createGrammar:(CTNode *)node{
    Grammar *g = [[Grammar alloc] init];
    g.code = node.code;
    
    if ([g.code isEqualToString:@"C"]) {
        if (node.value2) {
            g.data =  NSClassFromString(node.value2);
            g.data2 = [node.value2 stringByReplacingOccurrencesOfString:node.value
                                                             withString:@""];
        }
        else{
            g.data = NSClassFromString(node.value);
        }
    }
    else if ([g.code isEqualToString:@"I"]){}
    else{
        g.data = node.value;
        g.data2 = node.value2;
    }
    
    return g;
}

+ (CTNode *)_createNode:(Grammar *)g{
    CTNode *node = [[CTNode alloc] init];
    node.code = g.code;
    
    node.value = [Clay_Tree calcKey:g];
    
    if (__grammar_is_C(g)){
        if (g.data2){  //Clay_Struct,Clay_C,Clay_Object,...
            node.value2 = NSStringFromClass(g.data);
        }
        node.range = NSMakeRange(0, 0);
    }
    else if (__grammar_is_I(g)){
        node.range = NSMakeRange(0, 0);
        //node.value2 = g.data2;
    }
    else if (__grammar_is_IM(g)
             || __grammar_is_SM(g)
             || __grammar_is_P(g)
             ){
        node.range = NSMakeRange(0, node.value.length);
        node.value2 = g.data2;
    }
    else{
        node.range = NSMakeRange(0, node.value.length);
    }
    
    
    return node;
}

+ (NSString *)calcKey:(Grammar *)g{
    if (__grammar_is_C(g)) {
        if (g.data2){
            return [NSStringFromClass(g.data) stringByReplacingOccurrencesOfString:g.data2                                                                     withString:@""];
        }
        else{
            return NSStringFromClass(g.data);
        }
    }
    else if (__grammar_is_I(g)){
        return NSStringFromClass([g.data class]);
    }
    else if (__grammar_is_IM(g)
             || __grammar_is_SM(g)
             ){
        return [NSString stringWithFormat:@".%@(",g.data];
    }
    else if (__grammar_is_P(g)){
        return [NSString stringWithFormat:@".%@",g.data];
    }
    else{
        return g.data;
    }
    
    return nil;
}

+ (void)printHeads{
    [_heads enumerateKeysAndObjectsUsingBlock:^(id key, id  obj, BOOL * stop) {
        NSLog(@"node:%@ key:%@",obj,key);
    }];
}

@end
