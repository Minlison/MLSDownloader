//
//  LVRDownloadFileCenter.m
//  M3u8Download
//
//  Created by MinLison on 15/11/27.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "MLSDownloadFileTools.h"
#import "MLSDownloaderCommon.h"
#include <sys/param.h>
#include <sys/mount.h>

@interface MLSDownloadFileTools()
@end

@implementation MLSDownloadFileTools

+ (NSString *)saveFilePath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"VideoDownloads"];
    NSLog(@"存放地址：%@",filePath);
    return filePath;
}
// 获取磁盘剩余空间
+ (unsigned long long)getTotalDiskSpaceInBytes
{
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error)
            return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0)
    {
        space = -1;
    }
    return space;
}

// 获取指定单位的磁盘剩余空间
+ (CGFloat)getTotalDiskSpaceUseType:(TotalDiskSpaceType)type {
    CGFloat totalDiskSpace = [self getTotalDiskSpaceInBytes];
    switch (type) {
        case TotalDiskSpaceTypeKB:
            totalDiskSpace = totalDiskSpace / 1024;
            break;
        case TotalDiskSpaceTypeMB:
            totalDiskSpace = ((totalDiskSpace / 1024) / 1024);
            break;
        case TotalDiskSpaceTypeGB:
            totalDiskSpace = (((totalDiskSpace / 1024) / 1024) / 1024);
            break;
        default:
            break;
    }
    return totalDiskSpace;
}
// 获取要下载的文件格式
+ (NSString *)fileFormatForUrlString:(NSString *)downloadUrl
{
    NSArray  * strArr = [downloadUrl componentsSeparatedByString:@"?"];
    if(strArr && strArr.count > 0)
    {
        NSString *realUrl = strArr.firstObject;
        strArr = [realUrl componentsSeparatedByString:@"."];
        if (strArr && strArr.count > 0)
        {
            return [NSString stringWithFormat:@".%@",strArr.lastObject];
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}
+ (BOOL)createFileSavePath:(NSString *)savePath
{
    BOOL  result = YES;
    if(savePath != nil && savePath.length > 0)
    {
        NSFileManager  * fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:savePath])
        {
            __autoreleasing NSError *error = nil;
            [fm createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:&error];
            if(error)
            {
                result = NO;
                NSLog(@"WHC_DownloadFileCenter: 文件存储路径创建失败");
            }
        }
    }
    else
    {
        result = NO;
        NSLog(@"WHC_DownloadFileCenter: 文件存储路径错误不能为空");
    }
    return result;
}
@end
