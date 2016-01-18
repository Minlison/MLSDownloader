//
//  NSMutableDictionary+SafeAccess.m
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import "NSMutableDictionary+MLSSafeAccess.h"

@implementation NSMutableDictionary (MLSSafeAccess)
- (id)safeValueForKey:(NSString *)safeKey {
    __block id safeObj = nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:safeKey]) {
            safeObj = obj;
        }
    }];
    
    return safeObj;
}

@end
