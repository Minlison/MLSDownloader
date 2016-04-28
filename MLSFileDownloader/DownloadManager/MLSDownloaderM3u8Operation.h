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


// 保存m3u8的列表信息
@property (strong, nonatomic, readonly) NSArray <MLSDownloaderM3u8SegmentInfo *>*segmentInfoList;

// 等待下载的数组
@property (strong, nonatomic, readonly) NSMutableArray <MLSDownloaderM3u8SegmentInfo *>*waitingDownloadArray;


@end
