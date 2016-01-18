//
//  NSMutableArray+SafeAccess.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (MLSSafeAccess)
// 移除第一个元素
- (BOOL)removeFirstObject;
// 移除前count个元素
- (BOOL)removeFirstObjectsUseCount:(NSInteger)count;
@end

@interface NSArray(SafeAccess)
- (id)safeObjectAtIndex:(NSInteger)index;
@end