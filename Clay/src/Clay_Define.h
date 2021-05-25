//
//  Clay_Define.h
//  Clay
//
//  Created by ris on 4/9/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

/*! copy from wax */
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
#define __Clay_IS_ARM64__ 1
#else
#define __Clay_IS_ARM64__ 0
#endif


#define clay_va_arg(__arguments__,__index__) (__arguments__.count > __index__) ? __arguments__[__index__]: nil

#define NJ_I(__v__) [NSString stringWithFormat:@"__%@__I",__v__]

#define __clay_prefix(__interface__) __interface__
#define __clay_prefix_str(__interface__) @""#__interface__

#define Clay_DEBUG_MODE 0

#define __grammar_is_I(grammar) ([((Grammar *)grammar).code isEqualToString:@"I"])
#define __grammar_is_C(grammar) ([((Grammar *)grammar).code isEqualToString:@"C"])
#define __grammar_is_SM(grammar) ([((Grammar *)grammar).code isEqualToString:@"SM"])
#define __grammar_is_IM(grammar) ([((Grammar *)grammar).code isEqualToString:@"IM"])
#define __grammar_is_P(grammar) ([((Grammar *)grammar).code isEqualToString:@"P"])

#define __NO_PARAM__    @"no_parameter_"

#define __EXPR__        @"clay_expr_"
#define __CLASS__       @"clay_class_"
#define __PROTOCOL__    @"clay_protocol_"
#define __SUPER__       @"clay_super_"

typedef NSMutableString CLStr;