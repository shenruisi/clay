@implementation ClayTestCase

- (void *)methodName:(id)param1 param2:(void *)param2 block:(void(^)())block{
    BOOL condiation = NO;
    
    if (condiation) { NSString *a = [[NSString alloc] initWithFormat:@"pass"];[a uppercaseString];}
    else{
        BOOL condiation2 = NO;
        if (condiation && condiation2) {
            NSLog(@"branch1");
        }
        else if (!condiation) {
            NSLog(@"branch2");
            
            for (int i = 0; i < 10; ++i) {
                if (i == 0) {
                    while (1) {
                        break;
                    }
                }
                else{
                    do{
                        NSLog(@"do while");
                    }while(0);
                }
            }
        }
        else{
            NSLog(@"branch else");
        }
    }
    
    int type;
    switch (type) {
        case 0:
            break;
        case 1:{
            if (condiation) {
                NSLog(@"if in case");
            }
        }
            break;
        default:
            break;
    }
    
    id innerBlock = ^{
        NSLog(@"this is a block");
    };
    
    ((void(^)())innerBlock)();
    
    NSDictionary *d = @{
        @"KEY":@[@"S1",@"S2"],
        @"KEY2":@(1),
        @"KEY3":@{
            @"SUBK1":@""
        }
    };
    
    
    
    return (void *)1;
}

@end