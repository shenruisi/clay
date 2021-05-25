//
//  Clay_Runtime.h
//  Clay
//
//  Created by ris on 5/30/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import "Clay_CLObjects.h"

/* Encoding Types */
#define _CL_ID          @"@"
#define _CL_CLASS       @"#"
#define _CL_SEL         @":"
#define _CL_CHR         @"c"
#define _CL_UCHR        @"C"
#define _CL_SHT         @"s"
#define _CL_USHT        @"S"
#define _CL_INT         @"i"
#define _CL_UINT        @"I"
#define _CL_LNG         @"l"
#define _CL_ULNG        @"L"
#define _CL_LNG_LNG     @"q"
#define _CL_ULNG_LNG    @"Q"
#define _CL_FLT         @"f"
#define _CL_DBL         @"d"
#define _CL_BFLD        @"b"
#define _CL_BOOL        @"B"
#define _CL_VOID        @"v"
#define _CL_UNDEF       @"?"
#define _CL_PTR         @"^"
#define _CL_CHARPTR     @"*"
#define _CL_ATOM        @"%"
#define _CL_ARY_B       @"["
#define _CL_ARY_E       @"]"
#define _CL_UNION_B     @"("
#define _CL_UNION_E     @")"
#define _CL_STRUCT_B    @"{"
#define _CL_STRUCT_E    @"}"
#define _CL_VECTOR      @"!"
#define _CL_CONST       @"r"

BOOL cl_isAutoStepExpr(CLExpr *expr);

CLExpr *cl_getAutoStepExpr();

CLExpr *cl_getExpr(NSString *ocStat);

/* 获取带有上下文的IMP指针 */
CLIMPContext *cl_getIMPContext(CLIMP *imp,NSInvocation *invocation);



