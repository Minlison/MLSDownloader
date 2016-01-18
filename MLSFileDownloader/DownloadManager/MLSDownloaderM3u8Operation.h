//
//  DownloaderM3u8Operation.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/8.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLSDownloadOperation.h"
@class MLSDownloaderM3u8SegmentInfo;
@interface MLSDownloaderM3u8Operation : MLSDownloadOperation 

// 下载信息
@property (copy, nonatomic, readonly) NSString *fileTsPath;

// 保存m3u8的列表信息
@property (strong, nonatomic, readonly) NSArray <MLSDownloaderM3u8SegmentInfo *>*segmentInfoList;

// 等待下载的数组
@property (strong, nonatomic, readonly) NSMutableArray <MLSDownloaderM3u8SegmentInfo *>*waitingDownloadArray;

// 当前正在下载的task
@property (strong, nonatomic, readonly) NSURLSessionDownloadTask *currentDownloadTask;

// ts文件信息
@property (assign, nonatomic, readonly) NSInteger totalTsCount;
@property (assign, nonatomic, readonly) NSInteger currentDownloadTsIndex;


// m3u8文件记录
@property (copy, nonatomic, readonly) NSString *header;
@property (copy, nonatomic, readonly) NSString *footer;

@property (copy, nonatomic, readonly) NSString *tempFileName;

@end
