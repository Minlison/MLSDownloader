//
//  LVRDownloadAccount.h
//  M3u8Download
//
//  Created by MinLison on 15/11/30.
//  Copyright © 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLSDownloadAccount : NSObject

// 读取下载状态
+ (void)recoverDownloadState;

// 保存下载状态---默认在程序终止时保存
+ (void)saveDownloadState;

@end
