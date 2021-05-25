//
//  Clay_Exception.h
//  Clay
//
//  Created by yin shen on 2/28/16.
//  Copyright (c) 2016 yin shen. All rights reserved.
//

typedef enum{
    e_canNotFindIncludeFile =  7901
}ClayException;

void __clay_exception_log(NSString *reason);