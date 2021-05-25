//
//  Clay_VM+Executor.h
//  Clay
//
//  Created by ris on 7/28/16.
//  Copyright © 2016 yin shen. All rights reserved.
//

#import <Clay/Clay_VM.h>

@class CLClass;
@interface Clay_VM (Executor)

void run(Clay_VM *this,CLClass *classObj);
@end
