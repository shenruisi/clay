//
//  Clay_CLObjects.m
//  Clay
//
//  Created by ris on 5/24/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_CLObjects.h"
#import <Clay/Clay_Runtime.h>

extern NSString *_clAutoStep;


@implementation CLObject
@end

@implementation CLExpr

- (id)copyWithZone:(NSZone *)zone{
    CLExpr *copy = [[[self class] allocWithZone:zone] init];
    copy->_ocStat = [self.ocStat copy];
    copy->_clStat = [self.clStat copy];
    copy->_rT = [self.rT copy];
    copy->_rN = [self.rN copy];
    copy->_inputs = self.inputs;
    
    return copy;
}

@end

@implementation CLBlock

- (id)init{
    if (self = [super init]) { self.type = CLB; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlock *copy = [[[self class] allocWithZone:zone] init];
    copy->_type = self.type;
    copy->_cond = [self.cond copy];
    copy->_codes = [self.codes copy];
    copy->_parent = self.parent;
    copy->_condition = [self.condition copy];
    
    return copy;
}

- (NSMutableArray *)codes{
    if (!_codes) {
        _codes = [[NSMutableArray alloc] init];
    }
    
    return _codes;
}

- (CLBlock *)getCurrentBlock{
    return self.codes.lastObject;
}

@end

@implementation CLBlockStat

- (id)init{
    if (self = [super init]) { self.type = CLStat; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlockStat *copy = [super copyWithZone:zone];
    copy->_expr = [self.expr copy];
    
    return copy;
}


- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendString:self.expr.ocStat];
    [desc appendString:@"\n"];
    return desc;
}

@end

@implementation CLBlockFor

- (id)init{
    if (self = [super init]) { self.type = CLFor; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlockFor *copy = [super copyWithZone:zone];
    copy->_step = [self.step copy];
    copy->_varInit = [self.varInit copy];
    
    return self;
}

- (void)setCond:(NSString *)cond{
    [super setCond:cond];
    
    NSArray *conds = [cond componentsSeparatedByString:@";"];
    
    if (conds.count == 1) { //for ( xx in xx)
        
        NSArray *splitForIn = [cond componentsSeparatedByString:@" "];
        
        CLBlockStat *stat = [[CLBlockStat alloc] init];
    
        NSMutableString *cap = [[NSMutableString alloc] init];
        
        for (int i = 0; i < splitForIn.count; ++i) {
            NSString *part = splitForIn[i];
            
            if (i == 0) {
                [cap appendString:part];
            }
            else if (i == 1){
                if ([part isEqualToString:@"*"]) {
                    [cap appendFormat:@" *%@",splitForIn[i+1]];
                }
                else{
                    [cap appendString:part];
                }
            }
            else  if ([part isEqualToString:@"in"]) {
                self.condition = cl_getExpr([NSString stringWithFormat:@"for_in_i < %@.count",splitForIn[i+1]]);
                [cap appendFormat:@" = [%@ objectAtIndex:for_in_i]",splitForIn[i+1]];
                break;
            }
        }
        
        stat.expr = cl_getExpr(cap);
        
        self.varInit = cl_getExpr(@"int for_in_i = 0");
        
        self.step = cl_getAutoStepExpr();
        
        [self.codes addObject:stat];
    }
    else{
        NSString *s1 = conds[0];
        NSString *s2 = conds[1];
        NSString *s3 = conds[2];
        
        if (s1.length > 0) { self.varInit = cl_getExpr(s1);}
        self.condition = s2.length == 0 ? cl_getExpr(@"YES"):cl_getExpr(s2);
        if (s3.length == 0) {
            if (nil == self.varInit) { self.step = nil; }
            else{ self.step = cl_getAutoStepExpr(); }
        }
        else{ self.step = cl_getExpr(s3); }
    }
    
   
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendFormat:@"for ( %@ ) {\n",self.cond];
    
    for (int i = 0; i < self.codes.count; ++i) {
        CLBlock *block = self.codes[i];
        [desc appendString:[block description]];
    }
    
    [desc appendString:@"}\n"];
    return desc;
}

@end

@implementation CLBlockIf

- (id)init{
    if (self = [super init]) { self.type = CLIf; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlockIf *copy = [super copyWithZone:zone];
    copy->_next = self.next;
    
    return copy;
}

- (void)setCond:(NSString *)cond{
    [super setCond:cond];
    
    self.condition = cl_getExpr(cond);
}

- (CLBlockIf *)getCurrentBranch{
    CLBlockIf *ifPtr = self;
    while (ifPtr.next) {
        ifPtr = ifPtr.next;
    }
    return ifPtr;
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    CLBlockIf *blockIf = (CLBlockIf *)self;
    [desc appendFormat:@"if ( %@ ) {\n",self.cond];
    
    for (int i = 0; i < self.codes.count; ++i) {
        CLBlock *block = self.codes[i];
        [desc appendString:[block description]];
    }
    
    [desc appendString:@"}\n"];
    
    while (blockIf.next) {
        blockIf = blockIf.next;
        blockIf.cond.length?[desc appendFormat:@"else if ( %@ ) {\n",blockIf.cond]:[desc appendString:@"else {\n"];
        for (int i = 0; i < blockIf.codes.count; ++i) {
            CLBlock *block = blockIf.codes[i];
            [desc appendString:[block description]];
        }
        
        [desc appendString:@"}\n"];
    }
    
    return desc;
}

@end

@implementation CLBlockWhile

- (id)init{
    if (self = [super init]) { self.type = CLWhile; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlockWhile *copy = [super copyWithZone:zone];
    
    return copy;
}

- (void)setCond:(NSString *)cond{
    [super setCond:cond];
    
    self.condition = cl_getExpr(cond);
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendFormat:@"while ( %@ ){\n",self.cond];
    
    for (int i = 0; i < self.codes.count; ++i){
        CLBlock *block = self.codes[i];
        [desc appendString:[block description]];
    }
    
    [desc appendString:@"}\n"];
    return desc;
}

@end

@implementation CLBlockSwitch

- (id)init{
    if (self = [super init]) { self.type = CLSwitch; }
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
    CLBlockSwitch *copy = [super copyWithZone:zone];
    copy->_caseSet = [self.caseSet mutableCopy];
    
    return copy;
}

- (NSMutableArray *)caseSet{
    if (!_caseSet) {
        _caseSet = [[NSMutableArray alloc] init];
    }
    
    return _caseSet;
}

- (void)setCond:(NSString *)cond{
    [super setCond:cond];
    
    self.condition = cl_getExpr(cond);
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    
    [desc appendFormat:@"switch ( %@ ) {\n",self.cond];
    
    for (int i = 0; i < self.caseSet.count; ++i) {
        CLBlockCase *blockCase = self.caseSet[i];
        [desc appendString:[blockCase description]];
    }
    
    [desc appendString:@"\n}\n"];
    
    
    return desc;
}

@end

@implementation CLBlockCase

- (id)init{
    if (self = [super init]) { self.type = CLCase; }
    return self;
}


- (id)copyWithZone:(NSZone *)zone{
    CLBlockCase *copy = [super copyWithZone:zone];
    copy->_isDefault = self.isDefault;
    
    return copy;
}

- (void)setCond:(NSString *)cond{
    [super setCond:cond];
    
    self.condition = cl_getExpr(cond);
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    if (self.isDefault){
        [desc appendFormat:@"default %@ :\n",self.cond];
    }
    else{
        [desc appendFormat:@"case %@ :\n",self.cond];
    }
    
    for (int i = 0; i < self.codes.count; ++i) {
        CLBlock *block = self.codes[i];
        [desc appendString:[block description]];
    }
    
    return desc;
}

@end

@implementation CLIMP

- (id)copyWithZone:(NSZone *)zone{
    CLIMP *copy = [[[self class] allocWithZone:zone] init];
    copy->_lineNo = self.lineNo;
    copy->_block = [self.block copy];
    copy->_inputs = [self.inputs mutableCopy];
    copy->_cls = [self.cls copy];
    copy->_sel = [self.sel copy];
    copy->_isClassMethod = self.isClassMethod;
    
    return copy;
}

- (CLBlock *)block{
    if (!_block) {
        _block = [[CLBlock alloc] init];
    }
    
    return _block;
}

- (NSMutableArray *)inputs{
    if (!_inputs) {
        _inputs = [[NSMutableArray alloc] init];
    }
    
    return _inputs;
}

- (NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];

    self.isClassMethod?[desc appendString:@"+ "]:[desc appendString:@"- "];
    
    [desc appendString:self.sel];
    [desc appendString:@"\n"];
    [desc appendString:@"{\n"];
    
    for (int i = 0; i < self.block.codes.count; ++i){
        CLBlock *block = self.block.codes[i];
        [desc appendString:[block description]];
    }
    
    [desc appendString:@"\n}\n"];
    
    return desc;
}

@end

@implementation CLIMPContext

- (instancetype)initWithIMP:(CLIMP *)imp{
    if (self = [super init]) {
        /*TODO maybe need copy*/
        self.block = [imp.block copy];
        self.lineNo = imp.lineNo;
        self.cls = imp.cls;
        self.sel = imp.sel;
        self.isClassMethod = imp.isClassMethod;
        self.inputs = [imp.inputs copy];
    }
    
    return self;
}
@end

@implementation CLIVar
@end

@implementation CLProperty

- (NSMutableArray *)attrs{
    if (!_attrs) {
        _attrs = [[NSMutableArray alloc] init];
    }
    
    return _attrs;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"@property %@ %@",self.T,self.V];
}

@end

@implementation CLClass

- (void)merge:(CLClass *)anotherInterface{
    for (NSString *protocol in anotherInterface.protocols){
        [self.protocols addObject:protocol];
    }
    
    for (CLProperty *property in anotherInterface.properties) {
        [self.properties addObject:property];
    } 
}

- (NSMutableArray *)protocols{
    if (!_protocols) {
        _protocols = [[NSMutableArray alloc] init];
    }
    
    return _protocols;
}

- (NSMutableArray *)properties{
    if (!_properties) {
        _properties = [[NSMutableArray alloc] init];
    }
    
    return _properties;
}

- (NSMutableArray *)imps{
    if (!_imps) {
        _imps = [[NSMutableArray alloc] init];
    }
    
    return _imps;
}

- (NSMutableDictionary *)ivars{
    if (!_ivars) {
        _ivars = [[NSMutableDictionary alloc] init];
    }
    
    return _ivars;
}

-(NSString *)description{
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendFormat:@"@interface %@ : %@ \n",self.class,self.superClass];
    for (int i = 0; i < self.protocols.count; ++i) {
        if (0 == i) {
            [desc appendString:@"<\n"];
        }
        
        [desc appendFormat:@"\t%@",self.protocols[i]];
        
        if (i == self.protocols.count - 1) {
            [desc appendString:@"\n>\n"];
        }
        else{
            [desc appendString:@","];
        }
    }
    
    if ([self.ivars.allKeys count] > 0){
        [desc appendString:@"{\n"];
        
        for (int n = 0; n < self.ivars.allKeys.count; ++n) {
            CLIVar *ivar = [self.ivars objectForKey:self.ivars.allKeys[n]];
            [desc appendFormat:@"%@ %@\n",ivar.typeEncoding,ivar.name];
        }
        
        [desc appendString:@"}\n"];
    }
    
    for (int j = 0; j < self.properties.count; ++j) {
        [desc appendFormat:@"%@\n",[self.properties[j] description]];
    }
    
    
    for (int m = 0; m < self.imps.count; ++m) {
        
        [desc appendString:[self.imps[m] description]];
    }
    
    return desc;
}


@end

