//
//  Clay_CLObjects.h
//  Clay
//
//  Created by ris on 5/24/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSMutableDictionary CLContext;


@interface CLObject : NSObject
@end

typedef enum {
    CLB = 0,
    CLStat,
    CLFor,
    CLForIn,
    CLWhile,
    CLDoWhile,
    CLSwitch,
    CLCase,
    CLIf
}CLBlockType;



@interface CLExpr : CLObject

@property (nonatomic, copy) NSString *ocStat;
@property (nonatomic, copy) NSString *clStat;
@property (nonatomic, copy) NSString *rN;
@property (nonatomic, copy) NSString *rT;
@property (nonatomic, assign) NSMutableDictionary *inputs;
@end

@interface CLBlock : CLObject

@property (nonatomic, copy) NSString *cond;
@property (nonatomic, strong) CLExpr *condition;
@property (nonatomic, assign) CLBlockType type;
@property (nonatomic, strong) NSMutableArray<CLBlock *> *codes;
@property (nonatomic, assign) CLBlock *parent;
@property (nonatomic, getter=getCurrentBlock) CLBlock *current;

@end

@interface CLBlockStat : CLBlock
@property (nonatomic, strong) CLExpr *expr;
@end

@interface CLBlockFor : CLBlock
@property (nonatomic, strong) CLExpr *step;
@property (nonatomic, strong) CLExpr *varInit;

@end

@interface CLBlockIf : CLBlock

@property (nonatomic, strong) CLBlockIf *next;
@property (nonatomic, getter=getCurrentBranch) CLBlockIf *currentBranch;
@end

@interface CLBlockWhile : CLBlock


@end

@interface CLBlockCase : CLBlock

@property (nonatomic, assign) BOOL isDefault;

@end

@interface CLBlockSwitch : CLBlock

@property (nonatomic, strong) NSMutableArray<CLBlockCase*> *caseSet;
@end

@interface CLIMP : CLObject <NSCopying>

@property (nonatomic, assign) NSInteger lineNo;
@property (nonatomic, strong) CLBlock *block;
@property (nonatomic, strong) NSMutableArray<NSString *> *inputs;
@property (nonatomic, copy) NSString *cls;
@property (nonatomic, copy) NSString *sel;
@property (nonatomic, assign) BOOL isClassMethod;

@end

@interface CLIMPContext : CLIMP

@property (nonatomic, strong) CLContext *context;

- (instancetype)initWithIMP:(CLIMP *)imp;
@end

@interface CLIVar : CLObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, assign) NSInteger sizeType;
@end

@interface CLProperty : CLObject

@property (nonatomic, copy) NSString *T;
@property (nonatomic, copy) NSString *V;
@property (nonatomic, strong) NSMutableArray<NSString *> *attrs;
@property (nonatomic, strong) CLIMP *getter;
@property (nonatomic, strong) CLIMP *setter;
@end

@interface CLClass : CLObject

@property (nonatomic, copy) NSString *class;
@property (nonatomic, copy) NSString *superClass;
@property (nonatomic, strong) NSMutableArray<NSString *> *protocols;
@property (nonatomic, strong) NSMutableArray<CLProperty *> *properties;
@property (nonatomic, strong) NSMutableArray<CLIMP *> *imps;
@property (nonatomic, strong) NSMutableDictionary *ivars;

- (void)merge:(CLClass *)anotherInterface;
@end