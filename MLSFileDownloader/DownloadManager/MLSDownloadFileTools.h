//
//  LVRDownloadFileCenter.h
//  M3u8Download
//
//  Created by MinLison on 15/11/27.
//  Copyright © 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSInteger, TotalDiskSpaceType)
{
    TotalDiskSpaceTypeKB = 0,
    TotalDiskSpaceTypeMB = 1,
    TotalDiskSpaceTypeGB = 2,
};
@interface MLSDownloadFileTools  : NSObject

// 剩余磁盘空间(字节单位)
+ (unsigned long long)getTotalDiskSpaceInBytes;

// 剩余磁盘空间(指定单位)
+ (CGFloat)getTotalDiskSpaceUseType:(TotalDiskSpaceType)type;

// 文件保存路径
+ (NSString *)saveFilePath;

// 获取要下载的文件格式
+ (NSString *)fileFormatForUrlString:(NSString *)downloadUrl;

// 根据路径创建文件（文件夹）
+ (BOOL)createFileSavePath:(NSString *)savePath;
@end
