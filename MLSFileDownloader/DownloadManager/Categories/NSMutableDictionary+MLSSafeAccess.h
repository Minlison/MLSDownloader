//
//  NSMutableDictionary+SafeAccess.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (MLSSafeAccess)
- (id)safeValueForKey:(NSString *)safeKey;
@end
