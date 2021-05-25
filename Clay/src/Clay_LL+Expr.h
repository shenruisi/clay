//
//  Clay_LL+Expr.h
//  Clay
//
//  Created by yin shen on 2/23/16.
//  Copyright (c) 2016 yin shen. All rights reserved.
//


#import "Clay_LL.h"

extern void *__invoke(id sender,SEL cmd,NSMutableArray *args);

@interface Clay_LL(Expr)

- (id)evaluateStatement:(NSString *)stat;
@end