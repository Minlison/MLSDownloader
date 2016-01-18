//
//  LVRDownloadFileCenter.m
//  M3u8Download
//
//  Created by MinLison on 15/11/27.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "MLSDownloadFileCenter.h"
#include <sys/param.h>
#include <sys/mount.h>
long long freeSpace();
@interface MLSDownloadFileCenter()
@end
@implementation MLSDownloadFileCenter
+ (instancetype)shareDownloadFileCenter {
    static MLSDownloadFileCenter *downloadFileCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadFileCenter = [[self alloc] init];
    });
    return downloadFileCenter;
}
+ (NSString *)saveFilePath {
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"VideoDownloads"];
    NSLog(@"存放地址：%@",filePath);
    return filePath;
}
// 获取磁盘剩余空间
+ (unsigned long long)getTotalDiskSpaceInBytes {
    unsigned long long  freeDiskLen = 0;
    NSString * docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager  * fm   = [NSFileManager defaultManager];
    NSDictionary   * dict = [fm attributesOfFileSystemForPath:docPath error:nil];
    if(dict){
        freeDiskLen = [dict[NSFileSystemFreeSize] unsignedLongLongValue];
    }
    return freeDiskLen;
}
long long freeSpace() {
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/", &buf) >= 0){
        freespace = (long long)buf.f_bsize * buf.f_bfree;
    }
    return freespace;
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
//获取要下载的文件格式
+ (NSString *)fileFormatForUrlString:(NSString *)downloadUrl {
    NSArray  * strArr = [downloadUrl componentsSeparatedByString:@"?"];
    if(strArr && strArr.count > 0){
        NSString *realUrl = strArr.firstObject;
        strArr = [realUrl componentsSeparatedByString:@"."];
        if (strArr && strArr.count > 0) {
            return [NSString stringWithFormat:@".%@",strArr.lastObject];
        }else {
            return nil;
        }
    }else{
        return nil;
    }
}
+ (BOOL)createFileSavePath:(NSString *)savePath {
    BOOL  result = YES;
    if(savePath != nil && savePath.length > 0){
        NSFileManager  * fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:savePath]){
            __autoreleasing NSError *error = nil;
            [fm createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:&error];
            if(error){
                result = NO;
                NSLog(@"WHC_DownloadFileCenter: 文件存储路径创建失败");
            }
        }
    }else{
        result = NO;
        NSLog(@"WHC_DownloadFileCenter: 文件存储路径错误不能为空");
    }
    return result;
}
@end
