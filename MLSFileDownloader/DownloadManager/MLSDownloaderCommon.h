//
//  MLSDownloaderCommon.h
//  testFileDownloader
//
//  Created by MinLison on 16/1/14.
//  Copyright © 2016年 orgz. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifndef MLSDownloaderCommon
#define MLSDownloaderCommon

#define NSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define portNum 54321

@class MLSDownloadOperation;
typedef void(^MLSDownloaderOperationCallBackBlock)(MLSDownloadOperation *operation, NSError *error);
typedef void(^MLSDownloaderProgressCallBackBlock)( MLSDownloadOperation *operation, CGFloat progress);
typedef void(^MLSDownloaderCompletionCallBackBlock)(MLSDownloadOperation *operation, NSURL *filePath, NSError *error);
typedef void(^DownloaderNetworkSpeedCompletionBlock) (CGFloat networkSpeed);

#endif