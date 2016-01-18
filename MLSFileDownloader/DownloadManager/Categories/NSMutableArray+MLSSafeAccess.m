//
//  NSMutableArray+SafeAccess.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "NSMutableArray+MLSSafeAccess.h"

@implementation NSMutableArray (MLSSafeAccess)
- (BOOL)removeFirstObject {
    BOOL result = NO;
    if (self.count >= 1) {
        [self removeObjectAtIndex:0];
        result = YES;
    }
    
    return result;
}
- (BOOL)removeFirstObjectsUseCount:(NSInteger)count {
    if (count == 0) {
        return YES;
    }
    
    BOOL result = NO;
    
    if (self.count >= count) {
        for (int i = 0; i < count; i++) {
            [self removeObjectAtIndex:0];
        }
        result = YES;
    }
    return result;
}

@end

@implementation NSArray (SafeAccess)

- (id)safeObjectAtIndex:(NSInteger)index {
    if ( self.count >= index - 1 ) {
        return [self objectAtIndex:index];
    }
    return nil;
}

@end